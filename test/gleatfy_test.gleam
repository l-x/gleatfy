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

fn subject() -> gleatfy.Builder {
  gleatfy.new()
  |> gleatfy.topic("topic")
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

pub fn empty_topic_test() {
  subject()
  |> gleatfy.topic(is: "")
  |> gleatfy.request
  |> should.be_error
  |> should.equal(gleatfy.InvalidTopic(""))
}

pub fn invalid_server_test() {
  subject()
  |> gleatfy.server("blah")
  |> gleatfy.request
  |> should.be_error
  |> should.equal(gleatfy.InvalidServerUrl("blah"))
}

pub fn without_message_cache_test() {
  subject()
  |> gleatfy.without_message_cache
  |> request
  |> has_headers([#("cache", "no")])
}

pub fn without_firebase_test() {
  subject()
  |> gleatfy.without_firebase
  |> request
  |> has_headers([#("firebase", "no")])
}

pub fn basic_auth_test() {
  subject()
  |> gleatfy.login(with: Basic("username", "password"))
  |> request
  |> has_headers([#("authorization", "Basic dXNlcm5hbWU6cGFzc3dvcmQ")])
}

pub fn token_auth_test() {
  subject()
  |> gleatfy.login(with: Token("token"))
  |> request
  |> has_headers([#("authorization", "Bearer token")])
}

pub fn message_test() {
  subject()
  |> gleatfy.message(is: "message message")
  |> request
  |> has_body("{\"message\":\"message message\",\"topic\":\"topic\"}")
}

pub fn title_test() {
  subject()
  |> gleatfy.title(is: "message title")
  |> request
  |> has_body("{\"title\":\"message title\",\"topic\":\"topic\"}")
}

pub fn priority_test() {
  let should_have_body = fn(p: Priority, body: String) -> Nil {
    subject()
    |> gleatfy.priority(is: p)
    |> request
    |> has_body(body)

    Nil
  }

  VeryLow |> should_have_body("{\"priority\":1,\"topic\":\"topic\"}")
  Low |> should_have_body("{\"priority\":2,\"topic\":\"topic\"}")
  Normal |> should_have_body("{\"priority\":3,\"topic\":\"topic\"}")
  High |> should_have_body("{\"priority\":4,\"topic\":\"topic\"}")
  VeryHigh |> should_have_body("{\"priority\":5,\"topic\":\"topic\"}")
}

pub fn tags_test() {
  subject()
  |> gleatfy.tags(are: [])
  |> request
  |> has_body("{\"tags\":[],\"topic\":\"topic\"}")

  subject()
  |> gleatfy.tags(are: ["one"])
  |> request
  |> has_body("{\"tags\":[\"one\"],\"topic\":\"topic\"}")

  subject()
  |> gleatfy.tags(are: ["one", "two"])
  |> request
  |> has_body("{\"tags\":[\"one\",\"two\"],\"topic\":\"topic\"}")
}

pub fn format_test() {
  subject()
  |> gleatfy.format(is: Text)
  |> request
  |> has_body("{\"markdown\":false,\"topic\":\"topic\"}")

  subject()
  |> gleatfy.format(is: Markdown)
  |> request
  |> has_body("{\"markdown\":true,\"topic\":\"topic\"}")
}

pub fn delay_test() {
  subject()
  |> gleatfy.delay(is: "1 year")
  |> request
  |> has_body("{\"delay\":\"1 year\",\"topic\":\"topic\"}")
}

pub fn call_test() {
  subject()
  |> gleatfy.call(to: "+123456789")
  |> request
  |> has_body("{\"call\":\"+123456789\",\"topic\":\"topic\"}")
}

pub fn email_test() {
  subject()
  |> gleatfy.email(to: "info@example.com")
  |> request
  |> has_body("{\"email\":\"info@example.com\",\"topic\":\"topic\"}")
}

pub fn click_url_test() {
  subject()
  |> gleatfy.click_url(is: "https://example.com")
  |> request
  |> has_body("{\"click\":\"https://example.com\",\"topic\":\"topic\"}")
}

pub fn icon_url_test() {
  subject()
  |> gleatfy.icon_url(is: "https://example.com")
  |> request
  |> has_body("{\"icon\":\"https://example.com\",\"topic\":\"topic\"}")
}

pub fn attachment_url_test() {
  subject()
  |> gleatfy.attachment_url(is: "https://example.com")
  |> request
  |> has_body("{\"attachment\":\"https://example.com\",\"topic\":\"topic\"}")
}

pub fn attachment_name_test() {
  subject()
  |> gleatfy.attachment_name(is: "filename.jpg")
  |> request
  |> has_body("{\"filename\":\"filename.jpg\",\"topic\":\"topic\"}")
}

pub fn actions_empty_test() {
  subject()
  |> gleatfy.actions(are: [])
  |> request
  |> has_body("{\"actions\":[],\"topic\":\"topic\"}")
}

pub fn view_action_test() {
  subject()
  |> gleatfy.actions(are: [View("view label", "https://example.com", True)])
  |> request
  |> has_body(
    "{\"actions\":[{\"action\":\"view\",\"label\":\"view label\",\"clear\":true,\"url\":\"https://example.com\"}],\"topic\":\"topic\"}",
  )
}

pub fn broadcast_action_test() {
  subject()
  |> gleatfy.actions(are: [
    Broadcast("view label", "some.in.tent", [#("ex", "tras")], False),
  ])
  |> request
  |> has_body(
    "{\"actions\":[{\"action\":\"broadcast\",\"label\":\"view label\",\"clear\":false,\"intent\":\"some.in.tent\",\"extras\":{\"ex\":\"tras\"}}],\"topic\":\"topic\"}",
  )
}

pub fn http_action_test() {
  let assert Ok(action_request) = request.to("https://example.com")

  let action_request =
    action_request
    |> request.set_header("X-Test", "test header")
    |> request.set_body("test body")
    |> request.set_method(http.Put)

  subject()
  |> gleatfy.actions(are: [Http("http label", action_request, False)])
  |> request
  |> has_body(
    "{\"actions\":[{\"action\":\"broadcast\",\"label\":\"http label\",\"clear\":false,\"method\":\"put\",\"url\":\"https://example.com/\",\"headers\":{\"x-test\":\"test header\"},\"body\":\"test body\"}],\"topic\":\"topic\"}",
  )
}
