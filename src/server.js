import { WebSocketServer } from 'ws'
import { nanoid } from 'nanoid'

const server = new WebSocketServer({ port: 8080 })
const players = new Map()          // ws -> {id, x, y, score}
const collected_coins = new Set() // coin ids — authoritative state

const send = (ws, obj) => ws.readyState === 1 && ws.send(JSON.stringify(obj))

function broadcast(obj, exclude = null) {
    for (const client of players.keys()) {
        if (client !== exclude) send(client, obj)
    }
}

server.on('connection', ws => {
    const player = { id: nanoid(8), x: 0, y: 0, score: 0 }
    players.set(ws, player)
    console.log("Player", player.id, "joined")

    broadcast({ action: 'player_joined', id: player.id, x: 0, y: 0 }, ws)

    ws.on('message', raw => {
        let data
        try { data = JSON.parse(raw) } catch { return }
        if (typeof data?.action !== 'string') return

        switch (data.action) {
            case 'login':
                send(ws, {
                    action: 'login',
                    uuid: player.id,
                    players: [...players.values()],           // now plain objects
                    coins: [...collected_coins]               // ← late join gets coin state
                })
                break

            case 'move':
                if (!Number.isFinite(data.x) || !Number.isFinite(data.y)) return
                player.x = data.x
                player.y = data.y
                broadcast({ action: 'move', id: player.id, x: player.x, y: player.y })
                break

            case 'collect_coin': {
                const id = data.id | 0
                if (collected_coins.has(id)) return           // ← duplicate/cheat rejected
                collected_coins.add(id)
                player.score++
                broadcast({ action: 'coin_success', id, by: player.id })
                break
            }
        }
    })

    ws.on('close', () => {
        players.delete(ws)
        console.log("Player", player.id, "left")
        broadcast({ action: 'player_left', id: player.id })   // tell the others
    })
})

server.on('error', e => console.error("Server error:", e))
