import gleam/erlang/process
import gleam/option.{None}
import gleam/otp/actor
import glisten
import redis/resp

pub fn main() {
  let assert Ok(_) =
    glisten.handler(fn(_conn) { #(Nil, None) }, fn(msg, state, conn) {
      let assert glisten.Packet(_ignore) = msg
      let assert Ok(_) = glisten.send(conn, resp.simple_string("PONG"))
      actor.continue(state)
    })
    |> glisten.serve(6379)

  process.sleep_forever()
}
