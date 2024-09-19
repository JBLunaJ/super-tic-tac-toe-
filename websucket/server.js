const WebSocket = require('ws');

const server = new WebSocket.Server({ port: 8080 });

let players = [];
let gameState = {
  globalBoard: Array(9).fill(null).map(() => Array(9).fill(null)), // 9 tableros, cada uno 3x3
  currentPlayer: 'X',
  nextBoardIndex: 4, // El primer movimiento siempre es en el tablero central (índice 4)
  individualBoardWinners: Array(9).fill(null), // Ganador de cada tablero (null, 'X', 'O')
  gameStarted: false
};

function checkWinner(board) {
  const lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // Horizontales
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // Verticales
    [0, 4, 8], [2, 4, 6]            // Diagonales
  ];
  for (const [a, b, c] of lines) {
    if (board[a] && board[a] === board[b] && board[a] === board[c]) {
      return board[a];
    }
  }
  return null;
}

function checkGlobalWinner() {
  const lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // Horizontales
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // Verticales
    [0, 4, 8], [2, 4, 6]            // Diagonales
  ];
  for (const [a, b, c] of lines) {
    if (gameState.individualBoardWinners[a] && 
        gameState.individualBoardWinners[a] === gameState.individualBoardWinners[b] &&
        gameState.individualBoardWinners[a] === gameState.individualBoardWinners[c]) {
      return gameState.individualBoardWinners[a];
    }
  }
  return null;
}

server.on('connection', (ws) => {
  if (players.length >= 2) {
    ws.send(JSON.stringify({ type: 'error', message: 'Partida en curso' }));
    ws.close();
    return;
  }

  const playerSymbol = players.length === 0 ? 'X' : 'O'; // Asignar 'X' al primer jugador y 'O' al segundo
  players.push({ ws, symbol: playerSymbol });
  console.log('New player connected as ' + playerSymbol);

  // Notificar al jugador cuál símbolo se le asignó
  ws.send(JSON.stringify({ type: 'symbol', message: `Se te asignó el símbolo ${playerSymbol}` }));

  // Si ya hay dos jugadores conectados, iniciar la partida
  if (players.length === 2) {
    gameState.gameStarted = true;
    players.forEach(({ ws, symbol }) => {
      ws.send(JSON.stringify({ type: 'start', gameState, message: `La partida ha comenzado. Tu símbolo es ${symbol}` }));
    });
  } else {
    ws.send(JSON.stringify({ type: 'waiting', message: 'Esperando a que se conecte otro jugador' }));
  }

  ws.on('message', (message) => {
    const data = JSON.parse(message);

    if (data.type === 'move') {
      const { row, col, player, boardIndex } = data;

      if (gameState.individualBoardWinners[boardIndex] !== null) {
        ws.send(JSON.stringify({ type: 'error', message: 'Este tablero ya tiene un ganador.' }));
        return;
      }

      if (gameState.globalBoard[boardIndex][row * 3 + col] === null && player === gameState.currentPlayer) {
        gameState.globalBoard[boardIndex][row * 3 + col] = player;
        
        // Verificar si se ha ganado el tablero individual
        const winner = checkWinner(gameState.globalBoard[boardIndex]);
        if (winner) {
          gameState.individualBoardWinners[boardIndex] = winner;
        }

        // Verificar si se ha ganado el tablero global
        const globalWinner = checkGlobalWinner();
        if (globalWinner) {
          players.forEach(({ ws }) => {
            if (ws.readyState === WebSocket.OPEN) {
              ws.send(JSON.stringify({
                type: 'gameOver',
                message: `El jugador ${globalWinner} ha ganado el juego global!`,
                globalWinner: globalWinner,
                individualBoardWinners: gameState.individualBoardWinners
              }));
            }
          });
          return;
        }

        // Actualizar el siguiente tablero a jugar (basado en la posición de la celda)
        gameState.nextBoardIndex = row * 3 + col;
        if (gameState.individualBoardWinners[gameState.nextBoardIndex] !== null) {
          gameState.nextBoardIndex = null; // Si el tablero está lleno, se puede jugar en cualquier tablero vacío
        }

        // Cambiar de turno
        gameState.currentPlayer = player === 'X' ? 'O' : 'X';

        // Enviar el nuevo estado del juego a todos los clientes
        players.forEach(({ ws }) => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: 'update', gameState }));
          }
        });
      } else {
        ws.send(JSON.stringify({ type: 'error', message: 'Movimiento inválido.' }));
      }
    }

    if (data.type === 'restart') {
      gameState = {
        globalBoard: Array(9).fill(null).map(() => Array(9).fill(null)),
        currentPlayer: 'X',
        nextBoardIndex: 4, // Reiniciar en el tablero central
        individualBoardWinners: Array(9).fill(null),
        gameStarted: true
      };
      players.forEach(({ ws, symbol }) => {
        ws.send(JSON.stringify({ type: 'start', gameState, message: `La partida se ha reiniciado. Tu símbolo es ${symbol}` }));
      });
    }
  });

  ws.on('close', () => {
    console.log('Player disconnected');
    players = players.filter(({ ws: playerWs }) => playerWs !== ws);
    gameState.gameStarted = false;
  });
});

console.log('WebSocket server is listening on ws://localhost:8080');
