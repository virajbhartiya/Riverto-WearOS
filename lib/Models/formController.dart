import 'dart:convert' as convert;
import 'package:rivertoWearOS/Models/formConstructor.dart';
import 'package:http/http.dart' as http;

class FormController {
  final void Function(String) callback;
  FormController(this.callback);

  static const String URL =
      "https://script.google.com/macros/s/AKfycbzHkagLtJDdOQyaxrdcJdYnXdlsTx9JbWCE02qi/exec";

  void submitForm(FormConstructor formConstructor) async {
    try {
      await http.get(URL + formConstructor.toParams()).then((response) {
        callback(convert.jsonDecode(response.body));
      });
    } catch (e) {}
  }
}
