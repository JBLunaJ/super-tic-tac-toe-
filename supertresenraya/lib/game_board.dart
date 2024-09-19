import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class GameBoard extends StatefulWidget {
  final WebSocketChannel? channel;
  final String? playerSymbol;
  final int? nextBoard;

  GameBoard({this.channel, this.playerSymbol, this.nextBoard});

  static List<List<String?>> boardStates = List.generate(9, (_) => List.filled(9, null));

  static void updateBoards(List<dynamic> globalBoard) {
    for (int boardIndex = 0; boardIndex < 9; boardIndex++) {
      for (int cellIndex = 0; cellIndex < 9; cellIndex++) {
        boardStates[boardIndex][cellIndex] = globalBoard[boardIndex][cellIndex];
      }
    }
  }

  @override
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  void _handleTap(int boardIndex, int row, int col) {
    if (GameBoard.boardStates[boardIndex][row * 3 + col] == null && widget.playerSymbol != null) {
      // Solo permitir jugar en el tablero indicado o cualquier tablero si es null
      if (widget.nextBoard == null || widget.nextBoard == boardIndex) {
        widget.channel?.sink.add(jsonEncode({
          'type': 'move',
          'boardIndex': boardIndex,
          'row': row,
          'col': col,
          'player': widget.playerSymbol,
        }));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Debes jugar en el tablero ${widget.nextBoard}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: 9,
        itemBuilder: (context, boardIndex) {
          return _buildIndividualBoard(boardIndex);
        },
      ),
    );
  }

  Widget _buildIndividualBoard(int boardIndex) {
    bool isNextBoard = widget.nextBoard == null || widget.nextBoard == boardIndex;

    return Container(
      decoration: BoxDecoration(
        color: isNextBoard ? Colors.white : Colors.grey[300],
        border: Border.all(
          color: isNextBoard ? Colors.greenAccent : Colors.black,
          width: isNextBoard ? 5 : 2,
        ),
        boxShadow: isNextBoard
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                ),
              ]
            : [],
      ),
      margin: EdgeInsets.all(5.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: 9,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, cellIndex) {
          final row = cellIndex ~/ 3;
          final col = cellIndex % 3;
          return GestureDetector(
            onTap: () => _handleTap(boardIndex, row, col),
            child: Container(
              margin: EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: GameBoard.boardStates[boardIndex][row * 3 + col] == null
                    ? Colors.white
                    : (GameBoard.boardStates[boardIndex][row * 3 + col] == 'X'
                        ? Colors.blue[200]
                        : Colors.red[200]),
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  GameBoard.boardStates[boardIndex][row * 3 + col] ?? '',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: GameBoard.boardStates[boardIndex][row * 3 + col] == 'X'
                        ? Colors.blue
                        : Colors.red,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
