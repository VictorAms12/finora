import 'package:flutter/material.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Mercado Negro',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF070707),
      colorScheme: const ColorScheme.dark(primary: Colors.white, surface: Color(0xFF121212)),
    ),
    home: const Splash(),
  );
}

class Splash extends StatefulWidget { const Splash({super.key}); @override State<Splash> createState()=>_SplashState(); }
class _SplashState extends State<Splash> {
  @override void initState(){ super.initState(); Future.delayed(const Duration(seconds:2),(){if(mounted) Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const Store()));}); }
  @override Widget build(BuildContext c)=>Scaffold(body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
    ClipRRect(borderRadius:BorderRadius.circular(28),child:Image.asset('assets/logo.jpg',width:190,height:190)),
    const SizedBox(height:22),const Text('MERCADO NEGRO',style:TextStyle(fontSize:29,fontWeight:FontWeight.w900,letterSpacing:2)),
    const SizedBox(height:8),const Text('Acesso restrito • conexão segura',style:TextStyle(color:Colors.white54)),
    const SizedBox(height:28),const SizedBox(width:180,child:LinearProgressIndicator()),
  ])));
}

class Store extends StatefulWidget { const Store({super.key}); @override State<Store> createState()=>_StoreState(); }
class _StoreState extends State<Store> {
  int cart=0;
  static const items=[
    ('Wi-Fi Premium','Sinal que pega até no quintal do vizinho','R\$ 9,99',Icons.wifi),
    ('Pendrive Misterioso','Provavelmente cheio de memes','R\$ 19,90',Icons.usb),
    ('Senha do Cofre da Lua','Não funciona em cofres terrestres','R\$ 49,90',Icons.lock_outline),
    ('Cupom Infinito','100% OFF em absolutamente nada','R\$ 0,01',Icons.confirmation_num_outlined),
    ('Modo Hacker','Deixa tudo com cara de filme','R\$ 29,90',Icons.terminal),
    ('Pacote Ultra Secreto','Nem a gente sabe o que tem','R\$ 99,90',Icons.inventory_2_outlined),
  ];
  void add(String n){setState(()=>cart++);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$n adicionado ao carrinho'),duration:const Duration(milliseconds:700)));}
  void finish(){
    showDialog(context:context,barrierDismissible:false,builder:(d)=>AlertDialog(
      icon:const Icon(Icons.sentiment_very_satisfied,size:64),title:const Text('PEGADINHA! 😂',textAlign:TextAlign.center),
      content:const Text('Não existe compra, pagamento ou mercado real.\nEsse app é só uma brincadeira.',textAlign:TextAlign.center),
      actions:[FilledButton(onPressed:()=>Navigator.pop(d),child:const Text('Voltar'))],
    ));
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(backgroundColor:Colors.black,title:Row(children:[ClipOval(child:Image.asset('assets/logo.jpg',width:38,height:38)),const SizedBox(width:10),const Text('Mercado Negro',style:TextStyle(fontWeight:FontWeight.w800))]),actions:[Padding(padding:const EdgeInsets.all(12),child:Center(child:Text('🛒 $cart',style:const TextStyle(fontWeight:FontWeight.bold))))]),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),color:const Color(0xFF121212),border:Border.all(color:Colors.white12)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('CATÁLOGO CONFIDENCIAL',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Itens suspeitos e completamente fictícios.',style:TextStyle(color:Colors.white60))])),
      const SizedBox(height:16),
      ...items.map((x)=>Card(color:const Color(0xFF121212),child:ListTile(leading:Icon(x.$4,size:30),title:Text(x.$1,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${x.$2}\n${x.$3}'),isThreeLine:true,trailing:FilledButton(onPressed:()=>add(x.$1),child:const Text('Comprar'))))),
      const SizedBox(height:12),FilledButton.icon(onPressed:cart==0?null:finish,icon:const Icon(Icons.lock_open),label:const Padding(padding:EdgeInsets.symmetric(vertical:16),child:Text('FINALIZAR COMPRA'))),const SizedBox(height:24),
    ]),
  );
}
