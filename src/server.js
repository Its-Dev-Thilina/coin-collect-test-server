import { WebSocketServer } from 'ws'
import { nanoid } from 'nanoid'

const server = new WebSocketServer({
    port: 8080
})

const players = new Map()
const collected_coins = new Map()

console.log("Server started on port 8080")

server.on('connection', ws => {
    console.log("Client connected")

    players.set(ws,
        {
            id: nanoid(8),
            x: 0,
            y: 0,
            score: 0
        }
    )

    console.log("Player", players.get(ws).id, " Joined")

    ws.on('message', message => {
        const data = JSON.parse(message);

        if (data.action === "login") {
            ws.send(JSON.stringify({
                action: "login",
                uuid: players.get(ws).id,
                players: [...players.entries()]
            }))
        } else if (data.action === "move") {
            // Update player position
            players.get(ws).x = data.x;
            players.get(ws).y = data.y;

            ws.send(JSON.stringify({
                action: "move",
                uuid: players.get(ws).id,
                players: [...players.entries()]
            }))
        } else if (data.action === "collect_coin") {
            console.log("Player collected a coin #" + data.id)

            players.get(ws).score++

            for (const [key, value] of players.entries()) {
                key.send(JSON.stringify({
                    action: "coin_success",
                    id: data.id,
                }))
            }
        }
    })

    ws.on('close', () => {
        console.log("Client disconnected")

        ws.send(JSON.stringify({
            action: "disconnect",
        }))

        players.delete(ws)
    })
})

server.on('error', error => {
    console.error("Server error:", error)
})
