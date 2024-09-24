import gleam/http
import gleam/http/request
import gleam/http/response
import gleatfy.{
  type Priority, Basic, Broadcast, High, Http, Low, Markdown, Normal, Text,
  Token, VeryHigh, VeryLow, View,
}
import gleeunit
import gleeunit/should

const empty_body = "{\"topic\":\"topic\"}"

pub fn main() {
  gleeunit.main()
}

fn subject() -> gleatfy.Builder {
  gleatfy.new()
  |> gleatfy.topic("topic")
}

fn test_send(
  builder: gleatfy.Builder,
  expected_body: String,
  expected_headers: List(#(String, String)),
) -> Result(String, gleatfy.Error(a)) {
  let send = fn(r: request.Request(String)) {
    r.body |> should.equal(expected_body)
    r.headers |> should.equal(expected_headers)

    Ok(response.Response(200, [], "{\"id\":\"ok\"}"))
  }

  builder
  |> gleatfy.send(using: send)
}

pub fn server_error_test() {
  subject()
  |> gleatfy.send(fn(_) {
    Ok(response.Response(
      456,
      [],
      "{\"code\":789,\"http\":456,\"error\":\"error message\"}",
    ))
  })
  |> should.be_error
  |> should.equal(gleatfy.ServerError(
    http_status: 456,
    code: 789,
    message: "error message",
  ))
}

pub fn invalid_response_test() {
  subject()
  |> gleatfy.send(fn(_) {
    Ok(response.Response(456, [], "this is an invalid response"))
  })
  |> should.be_error
  |> should.equal(gleatfy.InvalidServerResponse("this is an invalid response"))
}

pub fn empty_topic_test() {
  subject()
  |> gleatfy.topic(is: "")
  |> test_send("", [])
  |> should.equal(Error(gleatfy.InvalidTopic("")))
}

pub fn invalid_server_test() {
  subject()
  |> gleatfy.server("blah")
  |> test_send("", [])
  |> should.equal(Error(gleatfy.InvalidServerUrl("blah")))
}

pub fn without_message_cache_test() {
  subject()
  |> gleatfy.without_message_cache
  |> test_send(empty_body, [#("cache", "no")])
  |> should.be_ok
}

pub fn without_firebase_test() {
  subject()
  |> gleatfy.without_firebase
  |> test_send(empty_body, [#("firebase", "no")])
  |> should.be_ok
}

pub fn basic_auth_test() {
  subject()
  |> gleatfy.login(with: Basic("username", "password"))
  |> test_send(empty_body, [#("authorization", "Basic dXNlcm5hbWU6cGFzc3dvcmQ")])
  |> should.be_ok
}

pub fn token_auth_test() {
  subject()
  |> gleatfy.login(with: Token("token"))
  |> test_send(empty_body, [#("authorization", "Bearer token")])
  |> should.be_ok
}

pub fn message_test() {
  subject()
  |> gleatfy.message(is: Text("text message"))
  |> test_send("{\"message\":\"text message\",\"topic\":\"topic\"}", [])
  |> should.be_ok

  subject()
  |> gleatfy.message(is: Markdown("markdown message"))
  |> test_send(
    "{\"message\":\"markdown message\",\"markdown\":true,\"topic\":\"topic\"}",
    [],
  )
  |> should.be_ok
}

pub fn attachment_test() {
  subject()
  |> gleatfy.attachment_url(is: "https://example.com/image")
  |> test_send(
    "{\"attach\":\"https://example.com/image\",\"topic\":\"topic\"}",
    [],
  )
  |> should.be_ok

  subject()
  |> gleatfy.attachment_filename(is: "cat.gif")
  |> test_send("{\"filename\":\"cat.gif\",\"topic\":\"topic\"}", [])
  |> should.be_ok
}

pub fn title_test() {
  subject()
  |> gleatfy.title(is: "message title")
  |> test_send("{\"title\":\"message title\",\"topic\":\"topic\"}", [])
  |> should.be_ok
}

pub fn priority_test() {
  let should_have_body = fn(p: Priority, body: String) -> Nil {
    subject()
    |> gleatfy.priority(is: p)
    |> test_send(body, [])
    |> should.be_ok

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
  |> test_send("{\"tags\":[],\"topic\":\"topic\"}", [])
  |> should.be_ok

  subject()
  |> gleatfy.tags(are: ["one"])
  |> test_send("{\"tags\":[\"one\"],\"topic\":\"topic\"}", [])
  |> should.be_ok

  subject()
  |> gleatfy.tags(are: ["one", "two"])
  |> test_send("{\"tags\":[\"one\",\"two\"],\"topic\":\"topic\"}", [])
  |> should.be_ok
}

pub fn delay_test() {
  subject()
  |> gleatfy.delay(is: "1 year")
  |> test_send("{\"delay\":\"1 year\",\"topic\":\"topic\"}", [])
  |> should.be_ok
}

pub fn call_test() {
  subject()
  |> gleatfy.call(to: "+123456789")
  |> test_send("{\"call\":\"+123456789\",\"topic\":\"topic\"}", [])
  |> should.be_ok
}

pub fn email_test() {
  subject()
  |> gleatfy.email(to: "info@example.com")
  |> test_send("{\"email\":\"info@example.com\",\"topic\":\"topic\"}", [])
  |> should.be_ok
}

pub fn click_url_test() {
  subject()
  |> gleatfy.click_url(is: "https://example.com")
  |> test_send("{\"click\":\"https://example.com\",\"topic\":\"topic\"}", [])
  |> should.be_ok
}

pub fn icon_url_test() {
  subject()
  |> gleatfy.icon_url(is: "https://example.com")
  |> test_send("{\"icon\":\"https://example.com\",\"topic\":\"topic\"}", [])
  |> should.be_ok
}

pub fn actions_empty_test() {
  subject()
  |> gleatfy.actions(are: [])
  |> test_send("{\"actions\":[],\"topic\":\"topic\"}", [])
  |> should.be_ok
}

pub fn view_action_test() {
  subject()
  |> gleatfy.actions(are: [View("view label", "https://example.com", True)])
  |> test_send(
    "{\"actions\":[{\"action\":\"view\",\"label\":\"view label\",\"clear\":true,\"url\":\"https://example.com\"}],\"topic\":\"topic\"}",
    [],
  )
  |> should.be_ok
}

pub fn broadcast_action_test() {
  subject()
  |> gleatfy.actions(are: [
    Broadcast("view label", "some.in.tent", [#("ex", "tras")], False),
  ])
  |> test_send(
    "{\"actions\":[{\"action\":\"broadcast\",\"label\":\"view label\",\"clear\":false,\"intent\":\"some.in.tent\",\"extras\":{\"ex\":\"tras\"}}],\"topic\":\"topic\"}",
    [],
  )
  |> should.be_ok
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
  |> test_send(
    "{\"actions\":[{\"action\":\"broadcast\",\"label\":\"http label\",\"clear\":false,\"method\":\"put\",\"url\":\"https://example.com/\",\"headers\":{\"x-test\":\"test header\"},\"body\":\"test body\"}],\"topic\":\"topic\"}",
    [],
  )
  |> should.be_ok
}
