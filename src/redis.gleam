import gleam/erlang/process
import gleam/option.{None}
import gleam/otp/actor
import glisten
import redis/resp

pub fn main() {
  let assert Ok(_) =
    glisten.handler(fn(_conn) { #(Nil, None) }, fn(msg, state, conn) {
      let assert glisten.Packet(_ignore) = msg
      handle_ping(conn)
      actor.continue(state)
    })
    |> glisten.serve(6379)

  process.sleep_forever()
}

fn handle_ping(conn: glisten.Connection(a)) -> Nil {
  let assert Ok(_) = glisten.send(conn, resp.simple_string("PONG"))
  Nil
}
