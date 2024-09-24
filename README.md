# gleatfy

[![Package Version](https://img.shields.io/hexpm/v/gleatfy)](https://hex.pm/packages/gleatfy)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleatfy/)

```sh
gleam add gleatfy@1
```
```gleam
import gleam/hackney
import gleatfy.{
  High, Markdown, View, actions, message, priority, send, tags, title, topic,
}

pub fn main() {
  gleatfy.new()
  |> topic(is: "gleatfy_test_topic")
  |> priority(is: High)
  |> message(is: Markdown(
    "[**gleatfy**](https://github.com/l-x/gleatfy) is a [Gleam](https://gleam.run) client for the [ntfy](https://ntfy.sh) push notification API",
  ))
  |> title(is: "Aufgemerkt!")
  |> tags(are: ["warning", "important"])
  |> actions(are: [
    View("View on GitHub", "https://github.com/l-x/gleatfy", clear_after: True),
    View("Visit ntfy.sh", "https://ntfy.sh", clear_after: False),
    View("Visit gleam.run", "https://gleam.run", clear_after: False),
  ])
  |> send(using: hackney.send)
}
```

Further documentation can be found at <https://hexdocs.pm/gleatfy>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
