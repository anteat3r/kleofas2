import 'package:flutter/material.dart';

class WhatIfPage extends StatefulWidget {
  const WhatIfPage({Key? key}) : super(key: key);
  @override
  State<WhatIfPage> createState() => _WhatIfPageState();
}

class _WhatIfPageState extends State<WhatIfPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("WhatIf")),
    body: Column(),
  );
}
