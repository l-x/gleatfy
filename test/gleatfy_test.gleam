import gleam/http
import gleam/http/request
import gleatfy.{
  type Priority, Basic, Broadcast, High, Http, Low, Markdown, Normal, Text,
  Token, VeryHigh, VeryLow, View,
}
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

fn has_body(
  req: request.Request(String),
  body: String,
) -> request.Request(String) {
  req.body
  |> should.equal(body)

  req
}

fn has_headers(
  req: request.Request(String),
  headers: List(#(String, String)),
) -> request.Request(String) {
  req.headers
  |> should.equal(headers)

  req
}

fn request(builder: gleatfy.Builder) -> request.Request(String) {
  builder
  |> gleatfy.request
  |> should.be_ok
}

pub fn defaults_test() {
  gleatfy.new()
  |> request
  |> has_body("{\"topic\":\"\"}")
  |> has_headers([])
}

pub fn basic_auth_test() {
  gleatfy.new()
  |> gleatfy.login(with: Basic("username", "password"))
  |> request
  |> has_headers([#("authorization", "Basic dXNlcm5hbWU6cGFzc3dvcmQ")])
}

pub fn token_auth_test() {
  gleatfy.new()
  |> gleatfy.login(with: Token("token"))
  |> request
  |> has_headers([#("authorization", "Bearer token")])
}

pub fn topic_test() {
  gleatfy.new()
  |> gleatfy.topic(is: "message topic")
  |> request
  |> has_body("{\"topic\":\"message topic\"}")
}

pub fn message_test() {
  gleatfy.new()
  |> gleatfy.message(is: "message message")
  |> request
  |> has_body("{\"message\":\"message message\",\"topic\":\"\"}")
}

pub fn title_test() {
  gleatfy.new()
  |> gleatfy.title(is: "message title")
  |> request
  |> has_body("{\"title\":\"message title\",\"topic\":\"\"}")
}

pub fn priority_test() {
  let should_have_body = fn(p: Priority, body: String) -> Nil {
    gleatfy.new()
    |> gleatfy.priority(is: p)
    |> request
    |> has_body(body)

    Nil
  }

  VeryLow |> should_have_body("{\"priority\":1,\"topic\":\"\"}")
  Low |> should_have_body("{\"priority\":2,\"topic\":\"\"}")
  Normal |> should_have_body("{\"priority\":3,\"topic\":\"\"}")
  High |> should_have_body("{\"priority\":4,\"topic\":\"\"}")
  VeryHigh |> should_have_body("{\"priority\":5,\"topic\":\"\"}")
}

pub fn tags_test() {
  gleatfy.new()
  |> gleatfy.tags(are: [])
  |> request
  |> has_body("{\"tags\":[],\"topic\":\"\"}")

  gleatfy.new()
  |> gleatfy.tags(are: ["one"])
  |> request
  |> has_body("{\"tags\":[\"one\"],\"topic\":\"\"}")

  gleatfy.new()
  |> gleatfy.tags(are: ["one", "two"])
  |> request
  |> has_body("{\"tags\":[\"one\",\"two\"],\"topic\":\"\"}")
}

pub fn format_test() {
  gleatfy.new()
  |> gleatfy.format(is: Text)
  |> request
  |> has_body("{\"markdown\":false,\"topic\":\"\"}")

  gleatfy.new()
  |> gleatfy.format(is: Markdown)
  |> request
  |> has_body("{\"markdown\":true,\"topic\":\"\"}")
}

pub fn delay_test() {
  gleatfy.new()
  |> gleatfy.delay(is: "1 year")
  |> request
  |> has_body("{\"delay\":\"1 year\",\"topic\":\"\"}")
}

pub fn call_test() {
  gleatfy.new()
  |> gleatfy.call(to: "+123456789")
  |> request
  |> has_body("{\"call\":\"+123456789\",\"topic\":\"\"}")
}

pub fn email_test() {
  gleatfy.new()
  |> gleatfy.email(to: "info@example.com")
  |> request
  |> has_body("{\"email\":\"info@example.com\",\"topic\":\"\"}")
}

pub fn click_url_test() {
  gleatfy.new()
  |> gleatfy.click_url(is: "https://example.com")
  |> request
  |> has_body("{\"click\":\"https://example.com\",\"topic\":\"\"}")
}

pub fn icon_url_test() {
  gleatfy.new()
  |> gleatfy.icon_url(is: "https://example.com")
  |> request
  |> has_body("{\"icon\":\"https://example.com\",\"topic\":\"\"}")
}

pub fn attachment_url_test() {
  gleatfy.new()
  |> gleatfy.attachment_url(is: "https://example.com")
  |> request
  |> has_body("{\"attachment\":\"https://example.com\",\"topic\":\"\"}")
}

pub fn attachment_name_test() {
  gleatfy.new()
  |> gleatfy.attachment_name(is: "filename.jpg")
  |> request
  |> has_body("{\"filename\":\"filename.jpg\",\"topic\":\"\"}")
}

pub fn actions_empty_test() {
  gleatfy.new()
  |> gleatfy.actions(are: [])
  |> request
  |> has_body("{\"actions\":[],\"topic\":\"\"}")
}

pub fn view_action_test() {
  gleatfy.new()
  |> gleatfy.actions(are: [View("view label", "https://example.com", True)])
  |> request
  |> has_body(
    "{\"actions\":[{\"action\":\"view\",\"label\":\"view label\",\"clear\":true,\"url\":\"https://example.com\"}],\"topic\":\"\"}",
  )
}

pub fn broadcast_action_test() {
  gleatfy.new()
  |> gleatfy.actions(are: [
    Broadcast("view label", "some.in.tent", [#("ex", "tras")], False),
  ])
  |> request
  |> has_body(
    "{\"actions\":[{\"action\":\"broadcast\",\"label\":\"view label\",\"clear\":false,\"intent\":\"some.in.tent\",\"extras\":{\"ex\":\"tras\"}}],\"topic\":\"\"}",
  )
}

pub fn http_action_test() {
  let assert Ok(action_request) = request.to("https://example.com")

  let action_request =
    action_request
    |> request.set_header("X-Test", "test header")
    |> request.set_body("test body")
    |> request.set_method(http.Put)

  gleatfy.new()
  |> gleatfy.actions(are: [Http("http label", action_request, False)])
  |> request
  |> has_body(
    "{\"actions\":[{\"action\":\"broadcast\",\"label\":\"http label\",\"clear\":false,\"method\":\"put\",\"headers\":{\"x-test\":\"test header\"},\"body\":\"test body\"}],\"topic\":\"\"}",
  )
}
