import 'package:flutter/material.dart';

enum DialogAction { confirm, cancel }

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
          backgroundColor: Theme.of(context).accentColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 20.0),
              Container(
                child: Text(
                  body,
                  style: TextStyle(color: Colors.black, fontSize: 19.0),
                ),
              ),
              SizedBox(height: 20.0),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: ButtonTheme(
                        child: FlatButton(
                          onPressed: () =>
                              Navigator.of(context).pop(DialogAction.cancel),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ButtonTheme(
                        child: FlatButton(
                          onPressed: () =>
                              Navigator.of(context).pop(DialogAction.confirm),
                          child: const Text(
                            'Confirmar',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    return (action != null) ? action : DialogAction.cancel;
  }
}
