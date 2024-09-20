import gleam/http/request
import gleatfy
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
  |> gleatfy.login(with: gleatfy.Basic("username", "password"))
  |> request
  |> has_headers([#("authorization", "Basic dXNlcm5hbWU6cGFzc3dvcmQ")])
}

pub fn token_auth_test() {
  gleatfy.new()
  |> gleatfy.login(with: gleatfy.Token("token"))
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
  let creates = fn(p: gleatfy.Priority, body: String) -> Nil {
    gleatfy.new()
    |> gleatfy.priority(is: p)
    |> request
    |> has_body(body)

    Nil
  }

  gleatfy.VeryLow |> creates("{\"priority\":1,\"topic\":\"\"}")
  gleatfy.Low |> creates("{\"priority\":2,\"topic\":\"\"}")
  gleatfy.Normal |> creates("{\"priority\":3,\"topic\":\"\"}")
  gleatfy.High |> creates("{\"priority\":4,\"topic\":\"\"}")
  gleatfy.VeryHigh |> creates("{\"priority\":5,\"topic\":\"\"}")
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
  |> gleatfy.format(is: gleatfy.Text)
  |> request
  |> has_body("{\"markdown\":false,\"topic\":\"\"}")

  gleatfy.new()
  |> gleatfy.format(is: gleatfy.Markdown)
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
