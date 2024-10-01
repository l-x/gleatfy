import gleam/bit_array
import gleam/bool
import gleam/dynamic
import gleam/function
import gleam/http.{Post}
import gleam/http/request.{type Request} as req
import gleam/http/response.{type Response, Response}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result.{replace_error, try}
import gleam/uri

const default_server = "https://ntfy.sh"

pub type Error(a) {
  InvalidServerUrl(String)
  InvalidTopic(String)
  ClientError(a)
  InvalidServerResponse(String)
  ServerError(code: Int, http_status: Int, message: String)
}

pub type Priority {
  VeryHigh
  High
  Normal
  Low
  VeryLow
}

/// Authentication method to use
/// See https://docs.ntfy.sh/publish/#authentication
/// 
pub type Login {
  Basic(user: String, password: String)
  Token(token: String)
}

/// Defintion for action buttons. If `clear_after` is set to `True`
/// the message is marked as read after clicking on this button.
/// See https://docs.ntfy.sh/publish/#action-buttons
/// 
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

/// Notification message to send
/// 
pub type Message {
  Text(String)
  Markdown(String)
}

pub opaque type Builder {
  Builder(
    login: Option(Login),
    server: String,
    topic: String,
    message: Option(Message),
    markdown: Bool,
    title: Option(String),
    priority: Option(Priority),
    tags: Option(List(String)),
    delay: Option(String),
    call: Option(String),
    email: Option(String),
    attachment_url: Option(String),
    attachment_filename: Option(String),
    click_url: Option(String),
    icon_url: Option(String),
    actions: Option(List(Action)),
    without_message_cache: Bool,
    without_firebase: Bool,
  )
}

/// Creates a fresh notification message builder
/// 
pub fn new() -> Builder {
  Builder(
    login: None,
    server: default_server,
    topic: "",
    message: None,
    markdown: False,
    title: None,
    priority: None,
    tags: None,
    delay: None,
    call: None,
    email: None,
    attachment_url: None,
    attachment_filename: None,
    click_url: None,
    icon_url: None,
    actions: None,
    without_message_cache: False,
    without_firebase: False,
  )
}

/// Set the ntfy instance to use. Defaults to https://ntfy.sh
/// 
pub fn server(builder: Builder, is server: String) -> Builder {
  Builder(..builder, server:)
}

/// Set the authentication method and data. Defaults to no authentication
/// See https://docs.ntfy.sh/publish/#authentication
/// 
pub fn login(builder: Builder, with login: Login) -> Builder {
  Builder(..builder, login: Some(login))
}

/// Set the **mandatory** topic to send the notification to.
/// 
pub fn topic(builder: Builder, is topic: String) -> Builder {
  Builder(..builder, topic: topic)
}

/// Set the notification's message body.
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> message(Text("Plain text"))
/// ```
/// 
/// ```gleam
/// new() |> message(Markdown("**Markdown** text"))
/// ```
/// 
/// For markdown messages see https://docs.ntfy.sh/publish/#markdown-formatting
/// 
pub fn message(builder: Builder, is message: Message) -> Builder {
  Builder(..builder, message: Some(message))
}

/// Set the notification's title.
/// See https://docs.ntfy.sh/publish/#message-title
/// 
pub fn title(builder: Builder, is title: String) -> Builder {
  Builder(..builder, title: Some(title))
}

/// Set the notification's priority
/// See https://docs.ntfy.sh/publish/#message-priority
/// 
pub fn priority(builder: Builder, is priority: Priority) -> Builder {
  Builder(..builder, priority: Some(priority))
}

/// Set optional tags for the notification
/// See https://docs.ntfy.sh/publish/#tags-emojis
/// 
pub fn tags(builder: Builder, are tags: List(String)) -> Builder {
  Builder(..builder, tags: Some(tags))
}

/// Set an optinal delay for notification delivery
/// See https://docs.ntfy.sh/publish/#scheduled-delivery
/// 
pub fn delay(builder: Builder, is delay: String) -> Builder {
  Builder(..builder, delay: Some(delay))
}

/// Set an optional URL to open when the notification is clicked
/// See https://docs.ntfy.sh/publish/#click-action
/// 
pub fn click_url(builder: Builder, is click_url: String) -> Builder {
  Builder(..builder, click_url: Some(click_url))
}

/// Attach a file by a given URL
/// See https://docs.ntfy.sh/publish/#attach-file-from-a-url
/// 
pub fn attachment_url(builder: Builder, is attachment_url: String) -> Builder {
  Builder(..builder, attachment_url: Some(attachment_url))
}

/// Set a specific name for an attached file
/// See https://docs.ntfy.sh/publish/#attach-file-from-a-url
/// 
pub fn attachment_filename(builder: Builder, is filename: String) -> Builder {
  Builder(..builder, attachment_filename: Some(filename))
}

/// Set a notification icon by URL
/// https://docs.ntfy.sh/publish/#icons
/// 
pub fn icon_url(builder: Builder, is icon_url: String) -> Builder {
  Builder(..builder, icon_url: Some(icon_url))
}

/// Forward the notification to an email address
/// See https://docs.ntfy.sh/publish/#e-mail-notifications
/// 
pub fn email(builder: Builder, to email: String) -> Builder {
  Builder(..builder, email: Some(email))
}

/// Set a phone number to be called to read the message out loud using text-to-speech
/// See https://docs.ntfy.sh/publish/#phone-calls
/// 
pub fn call(builder: Builder, to number: String) -> Builder {
  Builder(..builder, call: Some(number))
}

/// Add a list of action buttons for the notification
/// See https://docs.ntfy.sh/publish/#action-buttons
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> actions(are: [View("Visit ntfy.sh", "https://ntfy.sh", True)])
/// ```
/// 
/// ```gleam
///   new()
/// |> actions(are: [
///   Broadcast(
///    "Take picture",
///     "io.heckel.ntfy.USER_ACTION",
///     [#("cmd", "pic"), #("camera", "front")],
///    False,
///  ),
/// ])
/// ```
/// 
/// ```gleam
///   new()
///   |> actions(are: [
///     Http(
///       "Close door",
///       {
///         let assert Ok(req) = request.to("https://api.mygarage.lan/")
/// 
///         req
///         |> request.set_method(http.Put)
///         |> request.set_header("Authorization", "Bearer zAzsx1sk..")
///         |> request.set_body("{\"action\": \"close\"}")
///       },
///       True,
///     ),
///   ])
/// }
/// ```
/// 
pub fn actions(builder: Builder, are actions: List(Action)) -> Builder {
  Builder(..builder, actions: Some(actions))
}

/// Tell the server not to cache this notification
/// See https://docs.ntfy.sh/publish/#message-caching
/// 
pub fn without_message_cache(builder: Builder) -> Builder {
  Builder(..builder, without_message_cache: True)
}

/// Tell the server not to send this notification to FCM
/// See https://docs.ntfy.sh/publish/#disable-firebase
/// 
pub fn without_firebase(builder: Builder) -> Builder {
  Builder(..builder, without_firebase: True)
}

/// Create the HTTP request, hands it over to `send_fn` and decodes its return value
/// 
/// ## Example
/// 
/// ```gleam
/// new() |> topic("alert") |> send(https.send)
/// /// -> Ok("message-id")
/// ```
/// 
pub fn send(
  builder: Builder,
  using send_fn: fn(Request(String)) -> Result(Response(String), a),
) -> Result(String, Error(a)) {
  use request <- try(request(for: builder))
  use response <- try(send_fn(request) |> result.map_error(ClientError))

  case response {
    Response(200, body:, ..) -> decode_success(body)
    Response(_, body:, ..) -> decode_error(body)
  }
}

fn request(for builder: Builder) -> Result(Request(String), Error(a)) {
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

fn decode_success(body: String) -> Result(String, Error(a)) {
  body
  |> json.decode(using: dynamic.decode1(
    function.identity,
    dynamic.field("id", dynamic.string),
  ))
  |> replace_error(InvalidServerResponse(body))
}

fn decode_error(body: String) -> Result(String, Error(a)) {
  let decode_error =
    dynamic.decode3(
      ServerError,
      dynamic.field("code", dynamic.int),
      dynamic.field("http", dynamic.int),
      dynamic.field("error", dynamic.string),
    )

  case json.decode(body, using: decode_error) {
    Ok(err) -> Error(err)
    Error(_) -> Error(InvalidServerResponse(body))
  }
}

fn request_body(from builder: Builder) -> String {
  [#("topic", json.string(builder.topic))]
  |> json_message(builder.message)
  |> optional("title", for: builder.title, with: json.string)
  |> optional("attach", for: builder.attachment_url, with: json.string)
  |> optional("filename", for: builder.attachment_filename, with: json.string)
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
