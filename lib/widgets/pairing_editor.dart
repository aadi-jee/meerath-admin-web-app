import 'package:flutter/material.dart';

class PairingEditor extends StatefulWidget {
  const PairingEditor({super.key,required this.sourceId,required this.items,
    required this.selected,required this.onChanged});
  final String sourceId;
  final List<Map<String,dynamic>> items;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  @override
  State<PairingEditor> createState()=>_PairingEditorState();
}
class _PairingEditorState extends State<PairingEditor> {
  String _search='';
  String name(String id) => widget.items.where((r)=>r['id']==id)
    .map((r)=>r['name_en'] as String).firstOrNull ?? 'Missing/archived item — remove this selection';
  void move(int i,int direction) {
    final next=[...widget.selected];
    final item=next.removeAt(i); next.insert(i+direction,item); widget.onChanged(next);
  }
  @override
  Widget build(BuildContext context) {
    final candidates=widget.items.where((r)=>r['id']!=widget.sourceId && !widget.selected.contains(r['id']) &&
      '${r['name_en']} ${r['name_ar']}'.toLowerCase().contains(_search.toLowerCase())).take(30).toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Recommended pairings',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      const Text('Select up to 3 items. Saved with Publish / Save Draft. Pairings are one-way. Hidden or unavailable items will not appear to customers.'),
      for(var i=0;i<widget.selected.length;i++) ListTile(
        contentPadding:EdgeInsets.zero,
        title:Text('${i+1}. ${name(widget.selected[i])}'),
        trailing:Row(mainAxisSize:MainAxisSize.min,children:[
          IconButton(tooltip:'Move up',onPressed:i==0?null:()=>move(i,-1),icon:const Icon(Icons.arrow_upward)),
          IconButton(tooltip:'Move down',onPressed:i==widget.selected.length-1?null:()=>move(i,1),icon:const Icon(Icons.arrow_downward)),
          IconButton(tooltip:'Remove pairing',onPressed:()=>widget.onChanged([...widget.selected]..removeAt(i)),icon:const Icon(Icons.close)),
        ])),
      const SizedBox(height:12),
      TextField(decoration:const InputDecoration(labelText:'Search menu items',prefixIcon:Icon(Icons.search)),
        onChanged:(v)=>setState(()=>_search=v)),
      const SizedBox(height:8),
      if(widget.selected.length==3) const Text('All 3 slots selected. Remove one to choose another.'),
      for(final item in candidates) ListTile(contentPadding:EdgeInsets.zero,
        title:Text(item['name_en'] as String),
        subtitle:Text('SAR ${(item['base_price'] as num).toStringAsFixed(2)} · ${item['status']}'),
        trailing:IconButton(tooltip:'Add pairing',icon:const Icon(Icons.add),
          onPressed:widget.selected.length>=3?null:()=>widget.onChanged([...widget.selected,item['id'] as String]))),
      if(candidates.isEmpty) const Text('No matching items.'),
    ]);
  }
}
