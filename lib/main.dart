import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
void main() async { WidgetsFlutterBinding.ensureInitialized(); await Db.i.database; runApp(const App()); }
class App extends StatelessWidget { const App({super.key}); @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'INVENTARIO CECOSA',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff124f88)),useMaterial3:true),home:const Home()); }
class S { final int id; final String zone; final bool done; final String? file; final DateTime updated; S(this.id,this.zone,this.done,this.file,this.updated); factory S.map(Map<String,Object?>m)=>S(m['id'] as int,m['zone'] as String,(m['done'] as int)==1,m['file'] as String?,DateTime.parse(m['updated'] as String)); }
class R { final int? id; final int sid; final String inv,label; final double kg; final DateTime at; R(this.id,this.sid,this.inv,this.label,this.kg,this.at); factory R.map(Map<String,Object?>m)=>R(m['id'] as int,m['sid'] as int,m['inv'] as String,m['label'] as String,(m['kg'] as num).toDouble(),DateTime.parse(m['at'] as String)); }
class Db { Db._(); static final i=Db._(); Database? _db; Future<Database> get database async { if(_db!=null)return _db!; _db=await openDatabase(p.join(await getDatabasesPath(),'cecosa.db'),version:1,onCreate:(d,v)async{await d.execute('CREATE TABLE sessions(id INTEGER PRIMARY KEY AUTOINCREMENT,zone TEXT NOT NULL,done INTEGER NOT NULL DEFAULT 0,file TEXT,updated TEXT NOT NULL)');await d.execute('CREATE TABLE records(id INTEGER PRIMARY KEY AUTOINCREMENT,sid INTEGER NOT NULL,inv TEXT NOT NULL,label TEXT NOT NULL,kg REAL NOT NULL,at TEXT NOT NULL)');});return _db!;} Future<int> create(String z)async=>(await database).insert('sessions',{'zone':z,'done':0,'updated':DateTime.now().toIso8601String()}); Future<List<S>> sessions(bool done)async=>(await(await database).query('sessions',where:'done=?',whereArgs:[done?1:0],orderBy:'updated DESC')).map(S.map).toList(); Future<List<R>> rows(int sid)async=>(await(await database).query('records',where:'sid=?',whereArgs:[sid],orderBy:'id ASC')).map(R.map).toList(); Future<void> add(R r)async{final d=await database;await d.insert('records',{'sid':r.sid,'inv':r.inv,'label':r.label,'kg':r.kg,'at':r.at.toIso8601String()});await d.update('sessions',{'updated':DateTime.now().toIso8601String()},where:'id=?',whereArgs:[r.sid]);} Future<void> del(int id)async=>await(await database).delete('records',where:'id=?',whereArgs:[id]); Future<void> finish(int id,String f)async=>await(await database).update('sessions',{'done':1,'file':f,'updated':DateTime.now().toIso8601String()},where:'id=?',whereArgs:[id]); }
class Export { static const ch=MethodChannel('cecosa/downloads'); static Future<String> save(S s,List<R> rs)async{final b=ex.Excel.createExcel(),sh=b['Recuento'];final old=b.getDefaultSheet();if(old!=null&&old!='Recuento')b.delete(old);sh.appendRow([ex.TextCellValue('ZONA'),ex.TextCellValue('NUMERO INVENTARIO'),ex.TextCellValue('ETIQUETA ESCANEADA'),ex.TextCellValue('KG')]);for(final r in rs){sh.appendRow([ex.TextCellValue(s.zone),ex.TextCellValue(r.inv),ex.TextCellValue(r.label),ex.DoubleCellValue(r.kg)]);}final bytes=b.encode();if(bytes==null)throw Exception('No se pudo crear Excel');final z=s.zone.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'),'_');final n='${z}_${DateFormat('dd-MM-yyyy_HH-mm-ss').format(DateTime.now())}.xlsx';return await ch.invokeMethod<String>('save',{'name':n,'bytes':Uint8List.fromList(bytes)})??n;} }
class Home extends StatelessWidget { const Home({super.key}); Future<void> fresh(BuildContext c)async{final t=TextEditingController();final z=await showDialog<String>(context:c,builder:(d)=>AlertDialog(title:const Text('NUEVO RECUENTO'),content:TextField(controller:t,autofocus:true,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Zona'),onSubmitted:(v){if(v.trim().isNotEmpty)Navigator.pop(d,v.trim());}),actions:[FilledButton(onPressed:(){if(t.text.trim().isNotEmpty)Navigator.pop(d,t.text.trim());},child:const Text('EMPEZAR'))]));if(z==null||!c.mounted)return;final id=await Db.i.create(z);if(c.mounted)Navigator.push(c,MaterialPageRoute(builder:(_)=>Flow(S(id,z,false,null,DateTime.now()))));} @override Widget build(BuildContext c)=>Scaffold(body:Stack(fit:StackFit.expand,children:[Image.asset('assets/warehouse.png',fit:BoxFit.cover),Container(color:const Color(0x80102b45)),SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Icon(Icons.inventory_2,color:Colors.white,size:82),const SizedBox(height:16),const Text('INVENTARIO CECOSA',textAlign:TextAlign.center,style:TextStyle(color:Colors.white,fontSize:32,fontWeight:FontWeight.w800,letterSpacing:1.2)),const SizedBox(height:40),FilledButton.icon(onPressed:()=>fresh(c),icon:const Icon(Icons.add),label:const Padding(padding:EdgeInsets.all(17),child:Text('NUEVO RECUENTO'))),const SizedBox(height:14),FilledButton.tonalIcon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ListPage(false))),icon:const Icon(Icons.play_arrow),label:const Padding(padding:EdgeInsets.all(17),child:Text('CONTINUAR RECUENTO'))),const SizedBox(height:14),FilledButton.tonalIcon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ListPage(true))),icon:const Icon(Icons.folder),label:const Padding(padding:EdgeInsets.all(17),child:Text('RECUENTOS FINALIZADOS'))),const SizedBox(height:24),const Text('Visual in this file was generated with Microsoft Copilot.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white70,fontSize:10))])))))])); }
class ListPage extends StatefulWidget { final bool done; const ListPage(this.done,{super.key}); @override State<ListPage>createState()=>_ListState(); } class _ListState extends State<ListPage>{late Future<List<S>> f;@override void initState(){super.initState();f=Db.i.sessions(widget.done);}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.done?'FINALIZADOS':'CONTINUAR')),body:FutureBuilder<List<S>>(future:f,builder:(c,a){if(!a.hasData)return const Center(child:CircularProgressIndicator());if(a.data!.isEmpty)return const Center(child:Text('No hay recuentos'));return ListView.builder(itemCount:a.data!.length,itemBuilder:(c,i){final s=a.data![i];return ListTile(title:Text(s.zone),subtitle:Text(s.file??DateFormat('dd/MM/yyyy HH:mm').format(s.updated)),trailing:widget.done?const Icon(Icons.check_circle):const Icon(Icons.chevron_right),onTap:widget.done?null:()async{await Navigator.push(c,MaterialPageRoute(builder:(_)=>Flow(s)));if(mounted)setState(()=>f=Db.i.sessions(false));});});}));}
enum Phase{inventory,label,kg}
class Flow extends StatefulWidget {final S s;const Flow(this.s,{super.key});@override State<Flow>createState()=>_FlowState();}
class _FlowState extends State<Flow>{Phase phase=Phase.inventory;final inv=TextEditingController(),lab=TextEditingController(),kg=TextEditingController();final focus=FocusNode();List<R> rows=[];@override void initState(){super.initState();load();WidgetsBinding.instance.addPostFrameCallback((_){focus.requestFocus();});}@override void dispose(){inv.dispose();lab.dispose();kg.dispose();focus.dispose();super.dispose();}Future<void> load()async{final x=await Db.i.rows(widget.s.id);if(mounted)setState(()=>rows=x);}TextEditingController get ctl=>switch(phase){Phase.inventory=>inv,Phase.label=>lab,Phase.kg=>kg};String get heading=>switch(phase){Phase.inventory=>'NÚMERO DE INVENTARIO',Phase.label=>'ESCANEE LA ETIQUETA',Phase.kg=>'INTRODUZCA KILOS'};TextInputType get keyboard=>phase==Phase.label?TextInputType.none:const TextInputType.numberWithOptions(decimal:true);void refocus()=>WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)focus.requestFocus();});Future<void> next(String raw)async{final v=raw.trim();if(v.isEmpty){refocus();return;}if(phase==Phase.inventory){setState(()=>phase=Phase.label);refocus();return;}if(phase==Phase.label){setState(()=>phase=Phase.kg);refocus();return;}final n=double.tryParse(v.replaceAll(',','.'));if(n==null||n<0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Kilos no válidos')));refocus();return;}await Db.i.add(R(null,widget.s.id,inv.text.trim(),lab.text.trim(),n,DateTime.now()));inv.clear();lab.clear();kg.clear();await load();if(mounted){setState(()=>phase=Phase.inventory);refocus();}}Future<void> erase(R r)async{final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('¿Eliminar este registro?'),content:Text('Inventario ${r.inv} • ${r.kg.toStringAsFixed(2)} kg'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('CANCELAR')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('ELIMINAR'))]))??false;if(ok&&r.id!=null){await Db.i.del(r.id!);await load();refocus();}}Future<void> end()async{if(rows.isEmpty)return;final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('FINALIZAR'),content:Text('Exportar ${rows.length} registros a Excel.'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('CANCELAR')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('FINALIZAR'))]))??false;if(!ok){refocus();return;}final f=await Export.save(widget.s,rows);await Db.i.finish(widget.s.id,f);if(!mounted)return;await showDialog(context:context,builder:(d)=>AlertDialog(title:const Text('GUARDADO'),content:Text('Excel guardado en Descargas:\n$f'),actions:[FilledButton(onPressed:()=>Navigator.pop(d),child:const Text('ACEPTAR'))]));if(mounted)Navigator.pop(context);}
@override
Widget build(BuildContext c) {
  final keyboardOpen = MediaQuery.viewInsetsOf(c).bottom > 0;
  return Scaffold(
    resizeToAvoidBottomInset: false,
    appBar: AppBar(
      title: Text(widget.s.zone),
      actions: [IconButton(onPressed: end, icon: const Icon(Icons.save_alt))],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: keyboardOpen ? 6 : 5,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, keyboardOpen ? 8 : 20, 20, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(heading, textAlign: TextAlign.center, style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        key: ValueKey(phase), controller: ctl, focusNode: focus, autofocus: true,
                        keyboardType: keyboard, textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(suffixText: phase == Phase.kg ? 'kg' : null),
                        onSubmitted: next,
                      ),
                      const SizedBox(height: 10),
                      FilledButton(onPressed: () => next(ctl.text), child: const Text('ACEPTAR')),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: keyboardOpen ? 4 : 5,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(children: [Text('REGISTROS GUARDADOS (${rows.length})', style: const TextStyle(fontWeight: FontWeight.bold))]),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(child: Text('Sin registros guardados'))
                      : ListView.separated(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (c, i) {
                            final r = rows[rows.length - 1 - i];
                            return ListTile(
                              dense: true,
                              title: Text('Inv. ${r.inv} • ${r.kg.toStringAsFixed(2)} kg'),
                              subtitle: Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => erase(r)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
