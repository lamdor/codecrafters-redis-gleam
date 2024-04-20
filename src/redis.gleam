import gleam/erlang/process
import gleam/option.{None}
import gleam/bytes_builder.{type BytesBuilder}
import gleam/otp/actor
import gleam/result
import glisten
import redis/commands
import redis/database
import redis/resp

pub fn main() {
  let db = database.start()

  let assert Ok(_) =
    glisten.handler(fn(_conn) { #(State(db), None) }, handler)
    |> glisten.serve(6379)

  process.sleep_forever()
}

type State {
  State(database: process.Subject(database.Message))
}

fn handler(msg: glisten.Message(a), state: State, conn: glisten.Connection(a)) {
  let assert glisten.Packet(bits) = msg

  let resp_byte_builder = case resp.decode(bits) {
    Ok(resp.Array(resps)) -> {
      let handled_cmd = {
        use strings <- result.try(resp.to_string_list(resps))
        use cmd <- result.map(commands.from_string_list(strings))
        case cmd {
          commands.Ping -> handle_ping()
          commands.Echo(str) -> handle_echo(str)
          commands.Set(..) -> handle_set(cmd, state.database)
          commands.Get(..) -> handle_get(cmd, state.database)
        }
      }
      result.unwrap(handled_cmd, resp.simple_error_bytes("ERR unknown command"))
    }
    _ -> resp.simple_error_bytes("ERR Unable to decode")
  }

  let assert Ok(_) = glisten.send(conn, resp_byte_builder)

  actor.continue(state)
}

fn handle_ping() -> BytesBuilder {
  resp.simple_string_bytes("PONG")
}

fn handle_echo(str: String) -> BytesBuilder {
  resp.bulk_string_bytes(str)
}

fn handle_set(
  cmd: commands.Command,
  database: process.Subject(database.Message),
) -> BytesBuilder {
  let reply = process.new_subject()

  process.send(database, database.Set(cmd, reply))

  process.receive(reply, 1000)
  |> result.replace(resp.simple_string_bytes("OK"))
  |> result.unwrap(resp.simple_error_bytes("ERR did not save"))
}

fn handle_get(cmd: commands.Command, database) {
  let reply = process.new_subject()

  process.send(database, database.Get(cmd, reply))

  process.receive(reply, 1000)
  |> result.try(fn(val) {
    case val {
      database.ValueReply(val) -> option.to_result(val, Nil)
    }
  })
  |> result.map(resp.bulk_string_bytes)
  |> result.unwrap(resp.null_bytes())
}
