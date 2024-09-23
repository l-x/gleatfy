import gleam/bit_array
import gleam/bool
import gleam/http.{Post}
import gleam/http/request.{type Request} as req
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result.{replace_error, try}
import gleam/uri

const default_server = "https://ntfy.sh"

pub type Error {
  InvalidServerUrl(String)
  InvalidTopic(String)
}

pub type Priority {
  VeryHigh
  High
  Normal
  Low
  VeryLow
}

pub type Login {
  Basic(user: String, password: String)
  Token(token: String)
}

pub type Action {
  View(label: String, url: String, clear_after: Bool)
  Http(label: String, request: Request(String), clear_after: Bool)
  Broadcast(
    label: String,
    intent: String,
    extras: List(#(String, String)),
    clear_after: Bool,
  )
}

pub type Message {
  Text(String)
  Markdown(String)
  File(filename: String, url: String)
}

pub opaque type Builder {
  Builder(
    login: Option(Login),
    server: String,
    topic: String,
    message: Option(Message),
    title: Option(String),
    priority: Option(Priority),
    tags: Option(List(String)),
    delay: Option(String),
    call: Option(String),
    email: Option(String),
    click_url: Option(String),
    icon_url: Option(String),
    actions: Option(List(Action)),
    without_message_cache: Bool,
    without_firebase: Bool,
  )
}

pub fn new() -> Builder {
  Builder(
    login: None,
    server: default_server,
    topic: "",
    message: None,
    title: None,
    priority: None,
    tags: None,
    delay: None,
    call: None,
    email: None,
    click_url: None,
    icon_url: None,
    actions: None,
    without_message_cache: False,
    without_firebase: False,
  )
}

pub fn login(builder: Builder, with credentials: Login) -> Builder {
  Builder(..builder, login: Some(credentials))
}

pub fn server(builder: Builder, is server: String) -> Builder {
  Builder(..builder, server:)
}

pub fn topic(builder: Builder, is topic: String) -> Builder {
  Builder(..builder, topic: topic)
}

pub fn message(builder: Builder, is message: Message) -> Builder {
  Builder(..builder, message: Some(message))
}

pub fn title(builder: Builder, is title: String) -> Builder {
  Builder(..builder, title: Some(title))
}

pub fn priority(builder: Builder, is priority: Priority) -> Builder {
  Builder(..builder, priority: Some(priority))
}

pub fn tags(builder: Builder, are tags: List(String)) -> Builder {
  Builder(..builder, tags: Some(tags))
}

pub fn delay(builder: Builder, is delay: String) -> Builder {
  Builder(..builder, delay: Some(delay))
}

pub fn call(builder: Builder, to number: String) -> Builder {
  Builder(..builder, call: Some(number))
}

pub fn email(builder: Builder, to email: String) -> Builder {
  Builder(..builder, email: Some(email))
}

pub fn click_url(builder: Builder, is click_url: String) -> Builder {
  Builder(..builder, click_url: Some(click_url))
}

pub fn icon_url(builder: Builder, is icon_url: String) -> Builder {
  Builder(..builder, icon_url: Some(icon_url))
}

pub fn actions(builder: Builder, are actions: List(Action)) -> Builder {
  Builder(..builder, actions: Some(actions))
}

pub fn without_message_cache(builder: Builder) -> Builder {
  Builder(..builder, without_message_cache: True)
}

pub fn without_firebase(builder: Builder) -> Builder {
  Builder(..builder, without_firebase: True)
}

pub fn request(for builder: Builder) -> Result(Request(String), Error) {
  use request <- try(
    req.to(builder.server)
    |> replace_error(InvalidServerUrl(builder.server)),
  )

  use <- bool.guard(
    when: builder.topic == "",
    return: Error(InvalidTopic(builder.topic)),
  )

  request
  |> req.set_body(request_body(from: builder))
  |> req.set_method(Post)
  |> set_login(builder.login)
  |> set_message_cache(builder.without_message_cache)
  |> set_firebase(builder.without_firebase)
  |> Ok
}

fn request_body(from builder: Builder) -> String {
  [#("topic", json.string(builder.topic))]
  |> json_message(builder.message)
  |> optional("title", for: builder.title, with: json.string)
  |> optional("priority", for: builder.priority, with: json_priority)
  |> optional("tags", for: builder.tags, with: json.array(_, json.string))
  |> optional("delay", for: builder.delay, with: json.string)
  |> optional("call", for: builder.call, with: json.string)
  |> optional("email", for: builder.email, with: json.string)
  |> optional("click", for: builder.click_url, with: json.string)
  |> optional("icon", for: builder.icon_url, with: json.string)
  |> optional("actions", for: builder.actions, with: json.array(_, json_action))
  |> json.object
  |> json.to_string
}

fn optional(
  params: List(#(String, Json)),
  property name: String,
  for value: Option(a),
  with fun: fn(a) -> Json,
) -> List(#(String, Json)) {
  case value {
    None -> params
    Some(v) -> [#(name, fun(v)), ..params]
  }
}

fn json_message(
  params: List(#(String, Json)),
  for message: Option(Message),
) -> List(#(String, Json)) {
  case message {
    None -> params
    Some(Text(value)) -> [#("message", json.string(value)), ..params]
    Some(Markdown(value)) -> [
      #("message", json.string(value)),
      #("markdown", json.bool(True)),
      ..params
    ]
    Some(File(filename:, url:)) -> [
      #("attach", json.string(url)),
      #("filename", json.string(filename)),
      ..params
    ]
  }
}

fn json_priority(priority: Priority) -> Json {
  json.int(case priority {
    VeryHigh -> 5
    High -> 4
    Normal -> 3
    Low -> 2
    VeryLow -> 1
  })
}

fn json_string_map(items: List(#(String, String))) -> Json {
  items
  |> list.map(pair.map_second(_, json.string))
  |> json.object
}

fn json_action(action: Action) -> Json {
  case action {
    View(label:, url:, clear_after:) ->
      json_view_action(label, url, clear_after)
    Http(label:, request:, clear_after:) ->
      json_http_action(label, request, clear_after)
    Broadcast(label:, intent:, extras:, clear_after:) ->
      json_broadcast_action(label, intent, extras, clear_after)
  }
}

fn json_base_action(
  action: String,
  label: String,
  clear_after: Bool,
  properties: List(#(String, Json)),
) -> Json {
  [
    #("action", json.string(action)),
    #("label", json.string(label)),
    #("clear", json.bool(clear_after)),
    ..properties
  ]
  |> json.object
}

fn json_view_action(label: String, url: String, clear_after: Bool) -> Json {
  json_base_action("view", label, clear_after, [#("url", json.string(url))])
}

fn json_http_action(
  label: String,
  request: req.Request(String),
  clear_after: Bool,
) -> Json {
  json_base_action("broadcast", label, clear_after, [
    #("method", request.method |> http.method_to_string |> json.string),
    #("url", request |> req.to_uri |> uri.to_string |> json.string),
    #("headers", json_string_map(request.headers)),
    #("body", json.string(request.body)),
  ])
}

fn json_broadcast_action(
  label: String,
  intent: String,
  extras: List(#(String, String)),
  clear_after: Bool,
) -> Json {
  json_base_action("broadcast", label, clear_after, [
    #("intent", json.string(intent)),
    #("extras", json_string_map(extras)),
  ])
}

fn set_login(request: Request(String), login: Option(Login)) -> Request(String) {
  case login {
    None -> request
    Some(Token(token)) ->
      req.set_header(request, "authorization", "Bearer " <> token)
    Some(Basic(user, pass)) ->
      req.set_header(
        request,
        "authorization",
        "Basic "
          <> bit_array.base64_encode(
          bit_array.from_string(user <> ":" <> pass),
          False,
        ),
      )
  }
}

fn set_message_cache(
  request: Request(String),
  without_message_cache: Bool,
) -> Request(String) {
  case without_message_cache {
    True -> request |> req.set_header("cache", "no")
    False -> request
  }
}

fn set_firebase(
  request: Request(String),
  without_firebase: Bool,
) -> Request(String) {
  case without_firebase {
    True -> request |> req.set_header("firebase", "no")
    False -> request
  }
}
