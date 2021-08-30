class FormConstructor {
  String name, feedback, email;
  FormConstructor({this.name, this.feedback, this.email});

  String toParams() => "?name=$name&mail=$email&feedback=$feedback";
}
