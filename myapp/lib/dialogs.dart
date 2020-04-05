import 'package:flutter/material.dart';

enum DialogAction { yes, abort }

class Dialogs {
  static Future<DialogAction> yesAbortDialog(
    BuildContext context,
    String title,
    String body,
  ) async {
    final action = await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(title, 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
          backgroundColor: Colors.black87,
          content: Text(body,
            style: TextStyle(
              color: Colors.white
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ButtonTheme(
                  minWidth: 163.0,
                  child: FlatButton(
                  onPressed: () => Navigator.of(context).pop(DialogAction.abort),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18.0),),
                  ),
                ),
                ButtonTheme(
                  minWidth: 163.0,
                  child: FlatButton(
                  onPressed: () => Navigator.of(context).pop(DialogAction.yes),
                  child: const Text('Confirmar', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18.0),),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    return (action != null) ? action : DialogAction.abort;
  }
}