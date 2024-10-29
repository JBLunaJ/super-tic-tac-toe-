import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'game_board.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe de 9 Tableros',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  WebSocketChannel? channel;
  String? playerSymbol;
  String gameMessage = "Conectando...";
  bool isGameOver = false;
  bool playerWon = false;
  int? nextBoard; // Indica el próximo tablero en el que se debe jugar

  @override
  void initState() {
    super.initState();
    // Conectar al servidor WebSocket
    channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080'));

    // Escuchar mensajes del servidor
    channel?.stream.listen((message) {
      final decodedMessage = jsonDecode(message);

      if (decodedMessage['type'] == 'symbol') {
        // Asignación de símbolo
        setState(() {
          playerSymbol = decodedMessage['message'].split(" ").last;
          gameMessage = "Se te asignó el símbolo $playerSymbol";
        });
      } else if (decodedMessage['type'] == 'start') {
        // Iniciar la partida
        setState(() {
          gameMessage = "La partida ha comenzado. Juegas con el símbolo $playerSymbol";
          nextBoard = decodedMessage['gameState']['nextBoardIndex'];
          isGameOver = false; // Reiniciar variablesJlunadev
        });
      } else if (decodedMessage['type'] == 'update') {
        // Actualizar el tablero
        setState(() {
          GameBoard.updateBoards(decodedMessage['gameState']['globalBoard']);
          nextBoard = decodedMessage['gameState']['nextBoardIndex'];
        });
      } else if (decodedMessage['type'] == 'gameOver') {
        // Fin de la partida
        setState(() {
      //devby:JLuna
          isGameOver = true;
          playerWon = decodedMessage['globalWinner'] == playerSymbol;
          gameMessage = playerWon
              ? "¡Felicitaciones! Ganaste la partida global. ¡Eres un campeón!"
              : "Perdiste esta vez. ¡Sigue intentándolo!";
        });
      } else if (decodedMessage['type'] == 'error') {
        // Mostrar mensaje de error
        setState(() {
          gameMessage = decodedMessage['message'];
        });
      }
    });
  }

  void _restartGame() {
    // Enviar solicitud de reinicio al servidor
    channel?.sink.add(jsonEncode({
      'type': 'restart',
    }));
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tic Tac Toe de 9 Tableros'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            gameMessage,
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          GameBoard(channel: channel, playerSymbol: playerSymbol, nextBoard: nextBoard),
          if (isGameOver) ...[
            ElevatedButton(
              onPressed: _restartGame,
              child: Text("Reiniciar Juego"),
            ),
          ],
        ],
      ),
    );
  }
}
