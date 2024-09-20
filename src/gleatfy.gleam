import gleam/bit_array
import gleam/http.{Post}
import gleam/http/request.{type Request} as req
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result.{try}

const default_server = "https://ntfy.sh"

pub type Priority {
  VeryHigh
  High
  Normal
  Low
  VeryLow
}

pub type Format {
  Text
  Markdown
}

pub type Login {
  Basic(user: String, password: String)
  Token(token: String)
}

pub opaque type Builder {
  Builder(
    login: Option(Login),
    server: String,
    topic: String,
    message: Option(String),
    title: Option(String),
    priority: Option(Priority),
    tags: Option(List(String)),
    format: Option(Format),
    delay: Option(String),
    call: Option(String),
    email: Option(String),
    click_url: Option(String),
    icon_url: Option(String),
    attachment_url: Option(String),
    attachment_name: Option(String),
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
    format: None,
    delay: None,
    call: None,
    email: None,
    click_url: None,
    icon_url: None,
    attachment_url: None,
    attachment_name: None,
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

pub fn message(builder: Builder, is message: String) -> Builder {
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

pub fn format(builder: Builder, is format: Format) -> Builder {
  Builder(..builder, format: Some(format))
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

pub fn attachment_url(builder: Builder, is attachment_url: String) -> Builder {
  Builder(..builder, attachment_url: Some(attachment_url))
}

pub fn attachment_name(builder: Builder, is attachment_name: String) -> Builder {
  Builder(..builder, attachment_name: Some(attachment_name))
}

pub fn request(for builder: Builder) -> Result(Request(String), Nil) {
  use request <- try(req.to(builder.server))

  request
  |> req.set_body(request_body(from: builder))
  |> req.set_method(Post)
  |> set_login(builder.login)
  |> Ok
}

fn request_body(from builder: Builder) -> String {
  [#("topic", json.string(builder.topic))]
  |> optional("message", builder.message, json.string)
  |> optional("title", builder.title, json.string)
  |> optional("priority", builder.priority, int_priority)
  |> optional("tags", builder.tags, json.array(_, json.string))
  |> optional("markdown", builder.format, fn(f) { json.bool(f == Markdown) })
  |> optional("delay", builder.delay, json.string)
  |> optional("call", builder.call, json.string)
  |> optional("email", builder.email, json.string)
  |> optional("click", builder.click_url, json.string)
  |> optional("attachment", builder.attachment_url, json.string)
  |> optional("filename", builder.attachment_name, json.string)
  |> optional("icon", builder.icon_url, json.string)
  |> json.object
  |> json.to_string
}

fn optional(
  params: List(#(String, Json)),
  name,
  value: Option(a),
  fun: fn(a) -> Json,
) -> List(#(String, Json)) {
  case value {
    None -> params
    Some(v) -> [#(name, fun(v)), ..params]
  }
}

fn int_priority(priority: Priority) -> Json {
  json.int(case priority {
    VeryHigh -> 5
    High -> 4
    Normal -> 3
    Low -> 2
    VeryLow -> 1
  })
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
