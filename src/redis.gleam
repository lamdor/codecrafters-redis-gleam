import gleam/erlang/process
import gleam/option.{None}
import gleam/otp/actor
import gleam/bytes_builder
import glisten

pub fn main() {
  let assert Ok(_) =
    glisten.handler(fn(_conn) { #(Nil, None) }, fn(msg, state, conn) {
      let assert glisten.Packet(_ignore) = msg
      let assert Ok(_) =
        glisten.send(conn, bytes_builder.from_string("+PONG\r\n"))
      actor.continue(state)
    })
    |> glisten.serve(6379)

  process.sleep_forever()
}
