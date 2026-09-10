import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/menu_repository.dart';
import '../data/offer_rules.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_bits.dart';
import '../widgets/pairing_editor.dart';

class MenuItemFormScreen extends StatefulWidget {
  const MenuItemFormScreen({
    super.key,
    this.item,
    required this.onBack,
    this.initialTab = 0,
    this.onSaved,
    this.onSavingChanged,
  });

  final MenuItemData? item;
  final VoidCallback onBack;
  final int initialTab;
  final VoidCallback? onSaved;
  final ValueChanged<bool>? onSavingChanged;

  @override
  State<MenuItemFormScreen> createState() =>
      MenuItemFormScreenState();
}

class MenuItemFormScreenState
    extends State<MenuItemFormScreen> {
  late final TextEditingController _nameEn;
  late final TextEditingController _nameAr;
  late final TextEditingController _shortEn;
  late final TextEditingController _shortAr;
  late final TextEditingController _price;
  late final TextEditingController _comparePrice;
  late final TextEditingController _prepTime;
  late final TextEditingController _calories;
  late final TextEditingController _servingSize;
  late final TextEditingController _internalNotes;
  final _offerDiscountInput = TextEditingController();
  final _offerMaxQtyInput = TextEditingController();
  final _offerMinSpendInput = TextEditingController();
  String? _cleanSnapshot;
  List<String> _recommendedIds = [];
  List<Map<String,dynamic>> _pairingItems = [];
  bool _confirmingLeave = false;
Uint8List? _selectedImageBytes;
String? _selectedImageName;
bool _imageRemoved = false;
bool _imageDirty = false;
bool _scheduleChanged = false;
List<Map<String,dynamic>> _originalSchedules = [];
String? _imageUrl;
late final String _itemId;
bool _isLoading = true;
String? _loadError;
Map<String,dynamic> _attributes = {};
List<CategoryData> _categories = [];
List<SubcategoryData> _subcategories = [];
List<Map<String,dynamic>> _branches = [];
  int _tabIndex = 0;
  String _savedStatus = 'draft';
  int _spiceLevel = 2;

bool _isSaving = false;
  bool _available = true;
  bool _showInCustomerApp = true;
  bool _featured = false;
  bool _bestSeller = false;
  bool _newItem = false;
  bool _vatIncluded = true;

  bool _scheduleAllDay = true;
TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 0);
final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7};
  String _category = '';
  String _subcategory = '';

  final Set<String> _selectedBranches = {
    'All Branches',
  };

  late List<_AddonOption> _addons;

  // ⬇️ OFFER FIELDS (Naye) ⬇️
  bool _hasOffer = false;
  double? _offerDiscount;
  String? _offerType; // 'percentage' or 'fixed'
  DateTime? _offerValidFrom;
  DateTime? _offerValidTo;
  bool _offerActive = false;

  final _tabs = const [
    'Basic Info',
    'Pricing',
    'Options & Add-ons',
    'Availability',
    'Visibility & Media',
    'Offers', // ⬅️ NAYA TAB
    'Recommendations',
  ];

  @override
  void initState() {
    super.initState();

    _tabIndex = widget.initialTab.clamp(0, 6).toInt();
    final item = widget.item;
    _itemId=item?.id??MenuRepository.newId();
    _imageUrl=item?.imageUrl;
_selectedImageBytes = item?.imageBytes;
_selectedImageName = item?.imageName;
    _nameEn = TextEditingController(
      text: item?.name ?? '',
    );

    _nameAr = TextEditingController(
      text: item?.nameAr ?? '',
    );

    _shortEn = TextEditingController(
      text: item?.description ?? '',
    );

    _shortAr = TextEditingController(text:item?.descriptionAr??'');

    _price = TextEditingController(
      text: item?.price.toStringAsFixed(2) ?? '',
    );

    _comparePrice = TextEditingController(
      text: item?.compareAtPrice?.toStringAsFixed(2) ?? '',
    );

    _prepTime = TextEditingController(
      text: '${item?.prepTime ?? 25}',
    );

    _calories = TextEditingController(
      text: '${item?.calories ?? 520}',
    );

    _servingSize = TextEditingController(
      text: item?.servingSize ?? '1 plate',
    );

    _internalNotes = TextEditingController();

    _category=item?.categoryId??'';
    _subcategory=item?.subcategoryId??'';
    _spiceLevel=item?.spiceLevel??2;
    _available=item?.available??true;
    _featured=item?.featured??false;
    _bestSeller=item?.bestSeller??false;
    _newItem=item?.newItem??false;
    _addons=[];

    // ⬇️ OFFER FIELDS INIT ⬇️
    _hasOffer = item?.hasOffer ?? false;
    _offerDiscount = item?.offerDiscount;
    _offerDiscountInput.text = _offerDiscount?.toString() ?? '';
    _offerType = item?.offerType ?? 'percentage';
    _offerValidFrom = item?.offerValidFrom;
    _offerValidTo = item?.offerValidTo;
    _offerActive = item?.offerActive ?? false;

    _loadForm();
  }

  // Compare actual editable values at navigation time. Tab changes and focus
  // changes are not edits; controllers also cover fields without onChanged.
  String _editSnapshot() => jsonEncode({
    'recommended_ids': _recommendedIds,
    'text': [_nameEn.text, _nameAr.text, _shortEn.text, _shortAr.text,
      _price.text, _comparePrice.text, _prepTime.text, _calories.text,
      _servingSize.text, _internalNotes.text, _offerDiscountInput.text,
      _offerMaxQtyInput.text, _offerMinSpendInput.text],
    'category': [_category, _subcategory],
    'visibility': [_available, _showInCustomerApp, _featured, _bestSeller,
      _newItem, _vatIncluded, _spiceLevel],
    'branches': _selectedBranches.toList()..sort(),
    'days': _selectedDays.toList()..sort(),
    'schedule': [_scheduleAllDay, _startTime.hour, _startTime.minute,
      _endTime.hour, _endTime.minute, _scheduleChanged],
    'offer': [_hasOffer, _offerType, _offerActive,
      _offerValidFrom?.toIso8601String(), _offerValidTo?.toIso8601String()],
    'image': [_imageUrl, _selectedImageName, _imageRemoved,
      _selectedImageBytes == null ? null : base64Encode(_selectedImageBytes!)],
    'addons': [for (final option in _addons)
      [option.name, option.type, option.price, option.enabled, option.required]],
  });

  bool get isSaving => _isSaving;

  Future<bool> confirmLeave() async {
    if (_isSaving || _confirmingLeave) return false;
    if (_cleanSnapshot == null || _cleanSnapshot == _editSnapshot()) return true;
    _confirmingLeave = true;
    try {
      final discard = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Discard unsaved changes?'),
          content: const Text('Your changes have not been saved. Stay here to continue editing, or discard them to leave.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep editing')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Discard changes')),
          ],
        ),
      );
      return mounted && discard == true && !_isSaving;
    } finally {
      _confirmingLeave = false;
    }
  }

  void _setSaving(bool value) {
    if (!mounted || _isSaving == value) return;
    setState(() => _isSaving = value);
    widget.onSavingChanged?.call(value);
  }

  Future<void> _loadForm() async {
    setState((){_isLoading=true;_loadError=null;});
    try {
      final repo=MenuRepository();
      final categoryRows=await repo.loadCategories();
      final subRows=await repo.loadSubcategories(categoryRows.map((r)=>r['id'] as String).toList());
      final branches=await repo.loadBranches();
      final pairingItems=await repo.loadMenuItems();
      final recommendedIds=widget.item==null ? <String>[] : await repo.loadPairings(_itemId);
      Map<String,dynamic>? row;
      List<Map<String,dynamic>> schedules=[];
      List<String> assigned=[];
      String notes='';
      if(widget.item!=null) {
        row=await repo.loadItem(_itemId);
        schedules=await repo.loadSchedules(_itemId);
        assigned=await repo.loadItemBranches(_itemId);
        notes=await repo.loadNotes(_itemId);
      }
      if(!mounted)return;
      final loadedRow=row;
      setState((){
        _categories=categoryRows.map((r)=>CategoryData(id:r['id'] as String,name:r['name_en'] as String,
          nameAr:r['name_ar'] as String? ?? '',displayOrder:(r['sort_order'] as num).toInt(),active:r['is_active']==true)).toList();
        _subcategories=subRows.map((r)=>SubcategoryData(id:r['id'] as String,categoryId:r['category_id'] as String,
          name:r['name_en'] as String,nameAr:r['name_ar'] as String? ?? '',
          displayOrder:(r['sort_order'] as num).toInt(),active:r['is_active']==true)).toList();
        _branches=branches;
        _pairingItems=pairingItems;
        _recommendedIds=recommendedIds;
        _originalSchedules=schedules;
        if(loadedRow!=null){
          final data=loadedRow;
          _nameEn.text=data['name_en'] as String;
          _nameAr.text=data['name_ar'] as String? ?? '';
          _shortEn.text=data['description_en'] as String? ?? '';
          _shortAr.text=data['description_ar'] as String? ?? '';
          _price.text=(data['base_price'] as num).toString();
          _category=data['category_id'] as String;
          _subcategory=data['subcategory_id'] as String? ?? '';
          _savedStatus=data['status'] as String? ?? 'draft';
          _available=data['is_available']==true;
          _featured=data['is_featured']==true;
          _bestSeller=data['is_best_seller']==true;
          _newItem=data['is_new']==true;
          _showInCustomerApp=data['show_in_customer_app']!=false;
          _imageUrl=data['image_url'] as String?;
          _attributes=Map<String,dynamic>.from(data['attributes'] as Map? ?? {});
            // ⬇️ OFFER FIELDS READ FROM ATTRIBUTES ⬇️
          _hasOffer = _attributes['has_offer'] == true;
          _offerDiscount = OfferRules.number(_attributes['offer_discount']);
          _offerDiscountInput.text = _offerDiscount?.toString() ?? '';
          final offerType = _attributes['offer_type'];
          _offerType = offerType == 'fixed' ? 'fixed' : 'percentage';
          _offerValidFrom = OfferRules.parseDate(_attributes['offer_valid_from']);
          _offerValidTo = OfferRules.parseDate(_attributes['offer_valid_to']);
          _offerActive = _attributes['offer_active'] == true;
          _offerMaxQtyInput.text = _attributes['offer_max_qty']?.toString() ?? '';
          _offerMinSpendInput.text = _attributes['offer_min_regular_spend']?.toString() ?? '';
          _comparePrice.text=_attributes['compare_at_price']?.toString()??'';
          _prepTime.text=(_attributes['prep_time']??25).toString();
          _calories.text=(_attributes['calories']??0).toString();
          _servingSize.text=_attributes['serving_size'] as String? ?? '';
          _spiceLevel=(_attributes['spice_level'] as num?)?.toInt()??0;
          _vatIncluded=_attributes['vat_included']!=false;
          _selectedImageName=_attributes['image_name'] as String?;
          _internalNotes.text=notes;
          _addons=(_attributes['options'] as List? ?? []).map((o)=>_AddonOption(
            name:o['name'] as String,type:o['type'] as String,
            price:'SAR ${(o['price'] as num).toStringAsFixed(2)}',
            enabled:o['enabled']==true,required:o['required']==true)).toList();
          _selectedBranches..clear()..addAll(assigned);
          if(_attributes['all_branches']==true || (assigned.isEmpty&&!_attributes.containsKey('all_branches'))) _selectedBranches..clear()..add('All Branches');
          if(schedules.isNotEmpty){
            _selectedDays..clear()..addAll(schedules.where((d)=>d['is_available']==true).map((d)=>(d['day_of_week'] as num).toInt()));
            final first=schedules.firstWhere((d)=>d['is_available']==true,orElse:()=>schedules.first);
            _scheduleAllDay=first['start_time']==null;
            if(!_scheduleAllDay){_startTime=_parseTime(first['start_time'] as String);_endTime=_parseTime(first['end_time'] as String);}
          }
        } else {
          final active=_categories.where((c)=>c.active).toList();
          _category=active.isEmpty?'':active.first.id;
          _subcategory='';
        }
        _isLoading=false;
        _cleanSnapshot = _editSnapshot();
      });
    }catch(e){if(mounted)setState((){_isLoading=false;_loadError=MenuRepository.errorMessage(e);});}
  }

  TimeOfDay _parseTime(String text){final p=text.split(':');return TimeOfDay(hour:int.parse(p[0]),minute:int.parse(p[1]));}
  String _timeText(TimeOfDay t)=>'${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:00';
  String get _categoryName=>_categories.where((c)=>c.id==_category).map((c)=>c.name).firstOrNull??'';

  @override
  void dispose() {
    _nameEn.dispose();
    _nameAr.dispose();
    _shortEn.dispose();
    _shortAr.dispose();
    _price.dispose();
    _comparePrice.dispose();
    _prepTime.dispose();
    _calories.dispose();
    _servingSize.dispose();
    _internalNotes.dispose();
    _offerDiscountInput.dispose();
    _offerMaxQtyInput.dispose();
    _offerMinSpendInput.dispose();

    super.dispose();
  }

  List<SubcategoryData> _subcategoriesFor(String categoryId) {
    return _subcategories.where((s)=>s.categoryId==categoryId&&(s.active||s.id==_subcategory)).toList()
      ..sort((a,b)=>a.displayOrder.compareTo(b.displayOrder));
  }
Future<void> _showAddOptionDialog() async {
  final nameController = TextEditingController();
  final priceController = TextEditingController(text: '0.00');

  String type = 'Add-on';
  bool requiredOption = false;
  bool enabled = true;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Add New Option'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Option Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: nameController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Extra Chicken',
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: type,
                    dropdownColor: AppColors.surfaceAlt,
                    items: const [
                      DropdownMenuItem(
                        value: 'Add-on',
                        child: Text('Add-on'),
                      ),
                      DropdownMenuItem(
                        value: 'Option',
                        child: Text('Option / Choice'),
                      ),
                      DropdownMenuItem(
                        value: 'Variant',
                        child: Text('Variant / Size'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        type = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Extra Price',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'SAR  ',
                      hintText: '0.00',
                    ),
                  ),

                  const SizedBox(height: 14),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Required',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Customer must select this option',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    value: requiredOption,
                    onChanged: (value) {
                      setDialogState(() {
                        requiredOption = value;
                      });
                    },
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Active',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Show this option to customers',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    value: enabled,
                    onChanged: (value) {
                      setDialogState(() {
                        enabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: nameController.text.trim().isEmpty
                    ? null
                    : () {
                        final parsedPrice =
                            double.tryParse(priceController.text);
                        if(parsedPrice==null||!parsedPrice.isFinite||parsedPrice<0){
                          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content:Text('Enter a valid option price.')));return;
                        }

                        setState(() {
                          _addons.add(
                            _AddonOption(
                              name: nameController.text.trim(),
                              type: type,
                              price:
                                  'SAR ${parsedPrice.toStringAsFixed(2)}',
                              enabled: enabled,
                              required: requiredOption,
                            ),
                          );
                        });

                        Navigator.pop(dialogContext);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Add Option',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  nameController.dispose();
  priceController.dispose();
}
Future<void> _pickAvailabilityTime({required bool start}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: start ? _startTime : _endTime,
  );

  if (picked == null || !mounted) return;

  setState(() {
    if (start) {
      _scheduleChanged=true;
    _startTime = picked;
    } else {
      _scheduleChanged=true;
    _endTime = picked;
    }
  });
}
Future<void> _pickItemImage() async {
  final file = await FilePicker.pickFile(
    type: FileType.image,
  );

  if (file == null) {
    return;
  }

  final fileSize = await file.length();

  if (fileSize > 5 * 1024 * 1024) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image must be 5 MB or smaller.'),
      ),
    );
    return;
  }

  final bytes = await file.readAsBytes();

  if (!mounted) return;

  setState(() {
  _selectedImageBytes = bytes;
  _selectedImageName = file.name;
  _imageRemoved = false;
  _imageDirty = true;
});
}
void _removeItemImage() {
  setState(() {
    _selectedImageBytes = null;
    _selectedImageName = null;
    _imageRemoved = true;
    _imageDirty = false;
    _imageUrl = null;
  });
}
  Future<void> _saveItem({required bool draft}) async {
    if(_isSaving||_isLoading||_loadError!=null)return;
    final price=double.tryParse(_price.text.trim());
    final compare=_comparePrice.text.trim().isEmpty?null:double.tryParse(_comparePrice.text.trim());
    final prep=int.tryParse(_prepTime.text.trim());
    final calories=int.tryParse(_calories.text.trim());
    String? invalid;
    if(_nameEn.text.trim().isEmpty||price==null||!price.isFinite||price<0) invalid='Enter a name and valid price.';
    if(_comparePrice.text.trim().isNotEmpty&&(compare==null||!compare.isFinite||compare<0)) invalid='Enter a valid compare-at price.';
    if(prep==null||prep<0||calories==null||calories<0) invalid='Prep time and calories must be whole numbers, zero or higher.';
    if(!_categories.any((c)=>c.id==_category))invalid='Choose a category.';
    if(_subcategory.isNotEmpty&&!_subcategories.any((c)=>c.id==_subcategory&&c.categoryId==_category))invalid='Choose a valid subcategory.';
    if(!_scheduleAllDay&&_startTime.hour*60+_startTime.minute>=_endTime.hour*60+_endTime.minute)invalid='End time must be after start time.';
    final branchIds=_selectedBranches.contains('All Branches')
      ?_branches.where((b)=>b['is_active']==true).map((b)=>b['id'] as String).toList()
      :_selectedBranches.toList();
    if(branchIds.isEmpty)invalid='Select at least one branch.';
    final options=<Map<String,dynamic>>[];
    for(final o in _addons){
      final amount=double.tryParse(o.price.replaceAll('SAR','').trim());
      if(amount==null||!amount.isFinite||amount<0){invalid='An option has an invalid price.';break;}
      options.add({'name':o.name,'type':o.type,'price':amount,'enabled':o.enabled,'required':o.required});
    }
    final offerMaxQtyText = _offerMaxQtyInput.text.trim();
    final offerMaxQty = int.tryParse(offerMaxQtyText);
    final offerMinSpendText = _offerMinSpendInput.text.trim();
    final offerMinSpend = offerMinSpendText.isEmpty ? 0.0 : double.tryParse(offerMinSpendText);
    if (_hasOffer) {
      if (offerMinSpend == null || !offerMinSpend.isFinite || offerMinSpend < 0 ||
          offerMinSpend > 99999.99 || (offerMinSpendText.isNotEmpty &&
          !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(offerMinSpendText))) {
        invalid = 'Minimum regular-items spend must be 0–99999.99 SAR, with at most 2 decimal places.';
      }
      invalid = OfferRules.validate(price: price ?? -1, discount: _offerDiscount,
        type: _offerType, from: _offerValidFrom, to: _offerValidTo) ?? invalid;
      if (offerMaxQtyText.isNotEmpty &&
          (offerMaxQty == null || offerMaxQty < 1 || offerMaxQty > 999)) {
        invalid = 'Offer quantity limit must be a whole number from 1 to 999, or blank for unlimited.';
      }
    }
    if(invalid!=null){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(invalid)));return;}
    _setSaving(true);
    try {
      final repo=MenuRepository();
      if(_imageDirty&&_selectedImageBytes!=null){
        _imageUrl=await repo.uploadImage(_selectedImageBytes!,_selectedImageName??'image.jpg');
        _imageDirty=false; // Reuse the same upload if the database request needs retrying.
      }
      await repo.saveMenuItem({
        'id':_itemId,'category_id':_category,'subcategory_id':_subcategory.isEmpty?null:_subcategory,
        'name_en':_nameEn.text.trim(),'name_ar':_nameAr.text.trim(),
        'description_en':_shortEn.text.trim(),'description_ar':_shortAr.text.trim(),
        'base_price':price,'status':draft?'draft':'published',
        'is_available':_available,'is_featured':_featured,'is_best_seller':_bestSeller,'is_new':_newItem,
        'show_in_customer_app':_showInCustomerApp,'image_url':_imageRemoved?null:_imageUrl,
        'attributes':{..._attributes,'compare_at_price':compare,'prep_time':prep,'calories':calories,
          'serving_size':_servingSize.text.trim(),'spice_level':_spiceLevel,'vat_included':_vatIncluded,
          'options':options,'all_branches':_selectedBranches.contains('All Branches'),
          'image_name':_imageRemoved?null:_selectedImageName,
          // ⬇️ OFFER FIELDS SAVE ⬇️
          'has_offer': _hasOffer,
          'offer_discount': _offerDiscount,
          'offer_type': _offerType,
          'offer_valid_from': _offerValidFrom == null ? null : OfferRules.storageDate(_offerValidFrom!),
          'offer_valid_to': _offerValidTo == null ? null : OfferRules.storageDate(_offerValidTo!),
          'offer_active': _offerActive,
          'offer_max_qty': _hasOffer ? offerMaxQty : null,
          'offer_min_regular_spend': _hasOffer ? offerMinSpend : null,
        },
      }, schedules:!_scheduleChanged&&_originalSchedules.length==7?_originalSchedules:List.generate(7,(i)=>{'day_of_week':i+1,'is_available':_selectedDays.contains(i+1),
        'start_time':_scheduleAllDay?null:_timeText(_startTime),'end_time':_scheduleAllDay?null:_timeText(_endTime)}),
        branchIds:branchIds,notes:_internalNotes.text.trim(),recommendedIds:_recommendedIds);
      
      
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(draft?'Draft saved.':'Menu item saved.')));
      _cleanSnapshot = _editSnapshot();
      _setSaving(false);
      (widget.onSaved ?? widget.onBack)();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(MenuRepository.errorMessage(e))));}
    finally{if(mounted && _isSaving) _setSaving(false);}
  }

void _saveDraft() {
  _saveItem(draft: widget.item == null || _savedStatus != 'published');
}

void _publish() {
  _saveItem(draft: false);
}

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;

    if (_isLoading) {
  return const Center(child: CircularProgressIndicator());
}

if (_loadError != null) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_loadError!),
        TextButton(
          onPressed: _loadForm,
          child: const Text('Retry'),
        ),
        TextButton(
          onPressed: widget.onBack,
          child: const Text('Back'),
        ),
      ],
    ),
  );
}
    return Stack(children:[AbsorbPointer(absorbing:_isSaving,child:Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showPreview =
                  constraints.maxWidth >= 950;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  24,
                ),
                children: [
                  _TopBar(
                    editing: editing,
                    onBack: widget.onBack,
                  ),

                  const SizedBox(height: 20),

                  _TabBar(
                    tabs: _tabs,
                    selectedIndex: _tabIndex,
                    onSelected: (index) {
                      setState(() {
                        _tabIndex = index;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  if (showPreview)
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTabContent(),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 330,
                          child: _PreviewColumn(
                            item: widget.item,
                            name: _nameEn.text,
                            nameAr: _nameAr.text,
                            description: _shortEn.text,
                            price: _price.text,
                            comparePrice:
                                _comparePrice.text,
                            category: _categoryName,
                            available: _available,
                            featured: _featured,
                            bestSeller: _bestSeller,
                            newItem: _newItem,
                            prepTime: _prepTime.text,
                            spiceLevel: _spiceLevel,
                            imageBytes: _selectedImageBytes,
                            imageUrl: _imageUrl,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildTabContent(),
                    const SizedBox(height: 16),
                    _PreviewColumn(
                      item: widget.item,
                      name: _nameEn.text,
                      nameAr: _nameAr.text,
                      description: _shortEn.text,
                      price: _price.text,
                      comparePrice:
                          _comparePrice.text,
                      category: _categoryName,
                      available: _available,
                      featured: _featured,
                      bestSeller: _bestSeller,
                      newItem: _newItem,
                      prepTime: _prepTime.text,
                      spiceLevel: _spiceLevel,
                      imageBytes: _selectedImageBytes,
                            imageUrl: _imageUrl,
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        _BottomActions(
          editing: editing,
          onCancel: widget.onBack,
          onDraft: _saveDraft,
          onPublish: _publish,
        ),
      ],
    )),
    if(_isSaving)const Positioned(top:0,left:0,right:0,child:LinearProgressIndicator()),
    ]);
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 1:
        return _buildPricing();

      case 2:
        return _buildAddons();

      case 3:
        return _buildAvailability();

      case 4:
        return _buildVisibility();

      case 5:
        return _buildOfferTab(); // ⬅️ NAYA OFFER TAB
      case 6:
        return PairingEditor(sourceId:_itemId, items:_pairingItems, selected:_recommendedIds,
          onChanged:(ids)=>setState(()=>_recommendedIds=ids));

      default:
        return _buildBasicInfo();
    }
  }

  Widget _buildBasicInfo() {
    final categories=_categories.where((c)=>c.active||c.id==_category).toList();
    final subcategories=_subcategoriesFor(_category);
    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Basic Information',
                subtitle:
                    'Customer-facing menu item details.',
              ),

              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final sideBySide =
                      constraints.maxWidth >= 650;

                  if (!sideBySide) {
                    return Column(
                      children: [
                        _LabeledField(
                          label: 'Name (English)',
                          required: true,
                          child: TextField(
                            controller: _nameEn,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'e.g. Chicken Biryani',
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _LabeledField(
                          label: 'Name (Arabic)',
                          child: TextField(
                            controller: _nameAr,
                            textDirection:
                                TextDirection.rtl,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'اسم الصنف بالعربية',
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Name (English)',
                          required: true,
                          child: TextField(
                            controller: _nameEn,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'e.g. Chicken Biryani',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _LabeledField(
                          label: 'Name (Arabic)',
                          child: TextField(
                            controller: _nameAr,
                            textDirection:
                                TextDirection.rtl,
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'اسم الصنف بالعربية',
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  final sideBySide =
                      constraints.maxWidth >= 650;

                  final category =
                      _LabeledField(
                    label: 'Category',
                    required: true,
                    child:
                        DropdownButtonFormField<
                            String>(
                      initialValue: _category.isEmpty?null:_category,
                      dropdownColor:
                          AppColors.surfaceAlt,
                      decoration:
                          const InputDecoration(),
                      items: [
                        for (final category
                            in categories)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
  _category = value;

  final availableSubcategories =
      _subcategoriesFor(value);

  _subcategory = availableSubcategories.isNotEmpty
      ? availableSubcategories.first.id
      : '';
});
                      },
                    ),
                  );

                  final subcategory =
                      _LabeledField(
                    label: 'Subcategory',
                    child:
                        DropdownButtonFormField<
                            String>(
                      key: ValueKey('$_category/$_subcategory'),
initialValue: _subcategory,
                      dropdownColor:
                          AppColors.surfaceAlt,
                      decoration:
                          const InputDecoration(),
                      items: [
  const DropdownMenuItem(value:'',child:Text('None')),
  for (final subcategory in subcategories)
    DropdownMenuItem(
      value: subcategory.id,
      child: Text(subcategory.name),
    ),
],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _subcategory = value;
                        });
                      },
                    ),
                  );

                  if (!sideBySide) {
                    return Column(
                      children: [
                        category,
                        const SizedBox(height: 14),
                        subcategory,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: category),
                      const SizedBox(width: 14),
                      Expanded(
                        child: subcategory,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              _LabeledField(
                label: 'Short Description (English)',
                child: TextField(
                  controller: _shortEn,
                  maxLength: 120,
                  maxLines: 3,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Short customer-facing description...',
                    counterStyle: TextStyle(
                      color: AppColors.textDim,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _LabeledField(
                label: 'Description (Arabic)',
                child: TextField(
                  controller: _shortAr,
                  textDirection:
                      TextDirection.rtl,
                  maxLength: 120,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'وصف مختصر للصنف...',
                    counterStyle: TextStyle(
                      color: AppColors.textDim,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        _ImageUploadCard(
  imageBytes: _selectedImageBytes,
  imageName: _selectedImageName,
  imageUrl: _imageUrl,
  onTap: _pickItemImage,
  onRemove: _removeItemImage,
),
      ],
    );
  }

  Widget _buildPricing() {
    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Pricing',
                subtitle:
                    'Set selling price and item details.',
              ),

              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns =
                      constraints.maxWidth >= 650;

                  final fields = [
                    _LabeledField(
                      label: 'Base Price (SAR)',
                      required: true,
                      child: TextField(
                        controller: _price,
                        keyboardType:
                            TextInputType.number,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration:
                            const InputDecoration(
                          prefixText: 'SAR  ',
                          hintText: '0.00',
                        ),
                      ),
                    ),

                    _LabeledField(
                      label:
                          'Compare / Old Price',
                      child: TextField(
                        controller:
                            _comparePrice,
                        keyboardType:
                            TextInputType.number,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration:
                            const InputDecoration(
                          prefixText: 'SAR  ',
                          hintText: 'Optional',
                        ),
                      ),
                    ),
                  ];

                  if (!twoColumns) {
                    return Column(
                      children: [
                        fields[0],
                        const SizedBox(height: 14),
                        fields[1],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 14),
                      Expanded(child: fields[1]),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              _ToggleRow(
                title: 'VAT Included',
                subtitle:
                    'Price displayed to customers includes VAT.',
                value: _vatIncluded,
                onChanged: (value) {
                  setState(() {
                    _vatIncluded = value;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Item Details',
                subtitle:
                    'Optional information shown in the customer app.',
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 180,
                    child: _LabeledField(
                      label: 'Prep Time',
                      child: TextField(
                        controller:
                            _prepTime,
                        keyboardType:
                            TextInputType.number,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration:
                            const InputDecoration(
                          suffixText: 'mins',
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 180,
                    child: _LabeledField(
                      label: 'Calories',
                      child: TextField(
                        controller:
                            _calories,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          suffixText: 'kcal',
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 200,
                    child: _LabeledField(
                      label: 'Serving Size',
                      child: TextField(
                        controller:
                            _servingSize,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const Text(
                'Spice Level',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  for (var i = 1; i <= 3; i++)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        right: 8,
                      ),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                        onTap: () {
                          setState(() {
                            _spiceLevel = i;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment:
                              Alignment.center,
                          decoration:
                              BoxDecoration(
                            color:
                                i <= _spiceLevel
                                ? AppColors
                                      .accentSoft
                                : AppColors
                                      .surface,
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                            border: Border.all(
                              color:
                                  i <= _spiceLevel
                                  ? AppColors.accent
                                  : AppColors
                                        .border,
                            ),
                          ),
                          child: Icon(
                            Icons
                                .local_fire_department_rounded,
                            color:
                                i <= _spiceLevel
                                ? AppColors.accent
                                : AppColors
                                      .textDim,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  Text(
                    switch (_spiceLevel) {
                      1 => 'Mild',
                      2 => 'Medium',
                      _ => 'Spicy',
                    },
                    style: const TextStyle(
                      color:
                          AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddons() {
    return SectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  title: 'Options & Add-ons',
                  subtitle:
                      'Customize extras, variants and required options.',
                ),
              ),

              const SizedBox(width: 16),

              TextButton.icon(
  onPressed: _showAddOptionDialog,
                icon: const Icon(
                  Icons.add_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
                label: const Text(
                  'Add Option',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          for (var i = 0;
              i < _addons.length;
              i++) ...[
            _AddonRow(
              addon: _addons[i],
              onEnabledChanged: (value) {
                setState(() {
                  _addons[i] =
                      _addons[i].copyWith(
                    enabled: value,
                  );
                });
              },
              onRequiredChanged: (value) {
                setState(() {
                  _addons[i] =
                      _addons[i].copyWith(
                    required: value,
                  );
                });
              },
            ),

            if (i != _addons.length - 1)
              const Divider(
                color: AppColors.border,
                height: 26,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailability() {
    final branches = ['All Branches',..._branches.map((b)=>b['id'] as String)];

    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Availability',
                subtitle:
                    'Control whether customers can currently order this item.',
              ),

              const SizedBox(height: 18),

              _ToggleRow(
                title: 'Item Available',
                subtitle: _available
                    ? 'Customers can currently order this item.'
                    : 'Item is hidden as unavailable.',
                value: _available,
                onChanged: (value) {
                  setState(() {
                    _available = value;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Available At',
                subtitle:
                    'Select where this item can be ordered.',
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final branch
                      in branches)
                    FilterChip(
                      label: Text(branch=='All Branches'?branch:_branches.firstWhere((b)=>b['id']==branch)['name'] as String),
                      selected:
                          _selectedBranches
                              .contains(branch),
                      onSelected: (selected) {
                        setState(() {
                          if (branch ==
                              'All Branches') {
                            _selectedBranches
                              ..clear()
                              ..add(
                                'All Branches',
                              );
                            return;
                          }

                          _selectedBranches.remove(
                            'All Branches',
                          );

                          if (selected) {
                            _selectedBranches.add(
                              branch,
                            );
                          } else {
                            _selectedBranches.remove(
                              branch,
                            );
                          }

                        });
                      },
                      selectedColor:
                          AppColors.accentSoft,
                      checkmarkColor:
                          AppColors.accent,
                      side: BorderSide(
                        color:
                            _selectedBranches
                                .contains(
                                  branch,
                                )
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

              const SizedBox(height: 14),

      _buildAvailableDaysCard(),

      const SizedBox(height: 14),

      SectionCard(
        child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Schedule Availability',
                subtitle:
                    'Optionally limit ordering to specific times.',
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _ScheduleChoice(
                      label: 'All Day',
                      selected:
                          _scheduleAllDay,
                      onTap: () {
                        setState(() {
                          _scheduleChanged=true;
                          _scheduleAllDay = true;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ScheduleChoice(
                      label: 'Custom Time',
                      selected:
                          !_scheduleAllDay,
                      onTap: () {
                        setState(() {
                          _scheduleChanged=true;
                          _scheduleAllDay = false;
                        });
                      },
                    ),
                  ),
                ],
              ),

              if (!_scheduleAllDay) ...[
                const SizedBox(height: 18),

                Row(
  children: [
    Expanded(
      child: _TimeField(
        label: 'Start Time',
        value: _startTime.format(context),
        onTap: () {
          _pickAvailabilityTime(start: true);
        },
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _TimeField(
        label: 'End Time',
        value: _endTime.format(context),
        onTap: () {
          _pickAvailabilityTime(start: false);
        },
      ),
    ),
  ],
),
              ],
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildAvailableDaysCard() {
  const days = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];

  return SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Available Days',
          subtitle: 'Save available days. Custom times use the branch local time.',
        ),

        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in days)
              FilterChip(
                label: Text(day.$2),
                selected: _selectedDays.contains(day.$1),
                showCheckmark: true,
                selectedColor: AppColors.accentSoft,
                checkmarkColor: AppColors.accent,
                side: BorderSide(
                  color: _selectedDays.contains(day.$1)
                      ? AppColors.accent
                      : AppColors.border,
                ),
                onSelected: (selected) {
                  setState(() {
                    _scheduleChanged=true;
                    if (selected) {
                      _selectedDays.add(day.$1);
                    } else {
                      _selectedDays.remove(day.$1);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    ),
  );
}
  Widget _buildVisibility() {
    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Customer App Visibility',
                subtitle:
                    'Choose how this item is highlighted to customers.',
              ),

              const SizedBox(height: 18),
_ToggleRow(
  title: 'Show in Customer App',
  subtitle: _showInCustomerApp
      ? 'Allow this item in the customer menu when published and available.'
      : 'This item is hidden from the customer app.',
  value: _showInCustomerApp,
  onChanged: (value) {
    setState(() {
      _showInCustomerApp = value;
    });
  },
),

const Divider(
  color: AppColors.border,
  height: 26,
),
              _ToggleRow(
                title: 'Featured Item',
                subtitle:
                    'Show this item in featured menu sections.',
                value: _featured,
                onChanged: (value) {
                  setState(() {
                    _featured = value;
                  });
                },
              ),

              const Divider(
                color: AppColors.border,
                height: 26,
              ),

              _ToggleRow(
                title: 'Best Seller',
                subtitle:
                    'Display a bestseller badge on the customer app.',
                value: _bestSeller,
                onChanged: (value) {
                  setState(() {
                    _bestSeller = value;
                  });
                },
              ),

              const Divider(
                color: AppColors.border,
                height: 26,
              ),

              _ToggleRow(
                title: 'New Item',
                subtitle:
                    'Highlight this item as newly launched.',
                value: _newItem,
                onChanged: (value) {
                  setState(() {
                    _newItem = value;
                  });
                },
              ),
            ],
          ),
        ),


        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Internal Notes',
                subtitle:
                    'Only restaurant staff can see these notes.',
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _internalNotes,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Staff-only notes for this item...',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ⬇️ OFFER TAB UI ⬇️
  Widget _buildOfferTab() {
    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Offer Settings',
                subtitle: 'Set a discount or promotion for this menu item.',
              ),
              const SizedBox(height: 18),

              // Enable Offer Toggle
              _ToggleRow(
                title: 'Enable Offer',
                subtitle: _hasOffer
                    ? 'This item will appear in the Offers section.'
                    : 'Turn on to add this item to the Offers section.',
                value: _hasOffer,
                onChanged: (value) {
                  setState(() {
                    _hasOffer = value;
                    if (!value) {
                      _offerActive = false;
                    }
                  });
                },
              ),

              if (_hasOffer) ...[
                const Divider(color: AppColors.border, height: 26),

                // Discount Type
                const Text(
                  'Discount Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _offerType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (SAR)')),
                  ],
                  onChanged: (v) => setState(() => _offerType = v!),
                ),
                const SizedBox(height: 16),

                // Discount Value
                const Text(
                  'Discount Value',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _offerDiscountInput,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 20',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    _offerDiscount = double.tryParse(v);
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Maximum quantity per cart while offer is active',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _offerMaxQtyInput,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Blank = unlimited; e.g. 1 or 2',
                    helperText: '1–999. Counts all spice choices together. Extra units are blocked, not charged full price.',
                    helperMaxLines: 3,
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Minimum regular-items spend per discounted unit (SAR, VAT included)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _offerMinSpendInput,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Blank or 0 = no minimum; e.g. 30',
                    helperText: 'Only regular-priced items count; delivery and discounted items do not. Requirements add for every discounted unit in the cart.',
                    helperMaxLines: 4,
                  ),
                ),
                const SizedBox(height: 16),
                // Valid From
                const Text(
                  'Valid From',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickOfferDate(true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _offerValidFrom != null
                          ? _formatDate(_offerValidFrom!)
                          : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Valid To
                const Text(
                  'Valid To',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickOfferDate(false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _offerValidTo != null
                          ? _formatDate(_offerValidTo!)
                          : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Toggle
                _ToggleRow(
                  title: 'Offer Enabled',
                  subtitle: _offerActive
                      ? 'Enabled: the offer runs on its selected Saudi dates.'
                      : 'Offer is inactive and will not be shown.',
                  value: _offerActive,
                  onChanged: (value) => setState(() => _offerActive = value),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ⬇️ OFFER HELPER METHODS ⬇️
  Future<void> _pickOfferDate(bool isFrom) async {
    final stored = isFrom ? _offerValidFrom : _offerValidTo;
    final today = OfferRules.saudiDate();
    final initial = stored ?? today;
    final earliest = DateTime(today.year - 2, 1, 1);
    final latest = DateTime(today.year + 5, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: initial.isBefore(earliest) ? DateTime(initial.year, initial.month, initial.day) : earliest,
      lastDate: initial.isAfter(latest) ? DateTime(initial.year, initial.month, initial.day) : latest,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _offerValidFrom = picked;
        } else {
          _offerValidTo = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) =>
      OfferRules.formatDate(date);
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.editing,
    required this.onBack,
  });

  final bool editing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back to list',
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.accent,
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                editing
                    ? 'Edit Menu Item'
                    : 'Add Menu Item',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                editing
                    ? 'Update item details, pricing and availability.'
                    : 'Create a new item for your customer menu.',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0;
              i < tabs.length;
              i++)
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(10),
                onTap: () {
                  onSelected(i);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selectedIndex == i
                        ? AppColors.accentSoft
                        : AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    border: Border.all(
                      color:
                          selectedIndex == i
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color:
                          selectedIndex == i
                          ? AppColors.accent
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewColumn extends StatelessWidget {
  const _PreviewColumn({
    required this.item,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.price,
    required this.comparePrice,
    required this.category,
    required this.available,
    required this.featured,
    required this.bestSeller,
    required this.newItem,
    required this.prepTime,
    required this.spiceLevel,
    required this.imageBytes,
    this.imageUrl,
});

  final MenuItemData? item;

  final String name;
  final String nameAr;
  final String description;
  final String price;
  final String comparePrice;
  final String category;

  final bool available;
  final bool featured;
  final bool bestSeller;
  final bool newItem;

  final String prepTime;
  final int spiceLevel;
  final Uint8List? imageBytes;
  final String? imageUrl;
  

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer App Preview',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Live item card preview',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 160,
width: 330,
                      color: item?.color ??
                          AppColors.accentDeep,
                      child: Stack(
                        children: [
                          if (imageBytes != null)
  Positioned.fill(
    child: Image.memory(
      imageBytes!,
      fit: BoxFit.cover,
    ),
  )
else if(imageUrl?.isNotEmpty==true)
  Positioned.fill(child:Image.network(imageUrl!,fit:BoxFit.cover,
    errorBuilder:(_,e,s)=>const Center(child:Icon(Icons.broken_image_outlined))))
else
  const Center(
    child: Icon(
      Icons.restaurant_rounded,
      color: Colors.white70,
      size: 46,
    ),
  ),

                          if (bestSeller)
                            const Positioned(
                              top: 10,
                              left: 10,
                              child: _Badge(
                                text:
                                    'BESTSELLER',
                              ),
                            ),

                          if (newItem)
                            const Positioned(
                              top: 10,
                              right: 10,
                              child: _Badge(
                                text: 'NEW',
                              ),
                            ),

                          if (!available)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black
                                    .withValues(
                                  alpha: 0.62,
                                ),
                                alignment:
                                    Alignment.center,
                                child:
                                    const Text(
                                  'UNAVAILABLE',
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    letterSpacing:
                                        1.3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.isEmpty
                                      ? 'New menu item'
                                      : name,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                              ),

                              if (featured)
                                const Icon(
                                  Icons
                                      .star_rounded,
                                  color:
                                      AppColors
                                          .accent,
                                  size: 18,
                                ),
                            ],
                          ),

                          if (nameAr
                              .isNotEmpty) ...[
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              nameAr,
                              textDirection:
                                  TextDirection.rtl,
                              style:
                                  const TextStyle(
                                color: AppColors
                                    .textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            description.isEmpty
                                ? 'Item description will appear here.'
                                : description,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color: AppColors
                                  .textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Row(
                            children: [
                              Text(
                                'SAR ${price.isEmpty ? '0.00' : price}',
                                style:
                                    const TextStyle(
                                  color: AppColors
                                      .accent,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),

                              if (comparePrice
                                  .isNotEmpty) ...[
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  'SAR $comparePrice',
                                  style:
                                      const TextStyle(
                                    color:
                                        AppColors
                                            .textDim,
                                    fontSize: 11,
                                    decoration:
                                        TextDecoration
                                            .lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Row(
                            children: [
                              CategoryChip(
                                label: category,
                              ),

                              const Spacer(),

                              const Icon(
                                Icons.schedule,
                                color: AppColors
                                    .textMuted,
                                size: 14,
                              ),

                              const SizedBox(
                                width: 4,
                              ),

                              Text(
                                '${prepTime.isEmpty ? '25' : prepTime} mins',
                                style:
                                    const TextStyle(
                                  color: AppColors
                                      .textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Item Status',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              _PreviewStatusRow(
                label: 'Availability',
                value: available
                    ? 'Available'
                    : 'Unavailable',
                color: available
                    ? AppColors.success
                    : AppColors.danger,
              ),

              const SizedBox(height: 10),

              _PreviewStatusRow(
                label: 'Spice Level',
                value: switch (spiceLevel) {
                  1 => 'Mild',
                  2 => 'Medium',
                  _ => 'Spicy',
                },
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewStatusRow extends StatelessWidget {
  const _PreviewStatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),

        const Spacer(),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.12,
            ),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageUploadCard extends StatelessWidget {
  const _ImageUploadCard({
  required this.imageBytes,
    this.imageUrl,
  required this.imageName,
  required this.onTap,
  required this.onRemove,
});

  final Uint8List? imageBytes;
  final String? imageUrl;
  final String? imageName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Item Images',
            subtitle:
                'Recommended square image, minimum 800×800px.',
          ),

          const SizedBox(height: 16),

         InkWell(
  mouseCursor: SystemMouseCursors.click,
  onTap: onTap,
  child: Container(
    height: 160,
    width: 330,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderStrong,
                ),
              ),
              child: (imageBytes != null || imageUrl?.isNotEmpty==true)
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if(imageBytes!=null)Image.memory(imageBytes!,fit:BoxFit.cover)
                        else Image.network(imageUrl!,fit:BoxFit.cover,
                          errorBuilder:(_,e,s)=>const Center(child:Icon(Icons.broken_image_outlined))),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            color: Colors.black54,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.image_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    imageName ?? 'Selected image',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Change image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),

IconButton(
  tooltip: 'Remove image',
  onPressed: onRemove,
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
  icon: const Icon(
    Icons.delete_outline_rounded,
    color: Colors.redAccent,
    size: 18,
  ),
),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.accent,
                          size: 30,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Click to upload image',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'PNG or JPG · up to 5MB',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddonRow extends StatelessWidget {
  const _AddonRow({
    required this.addon,
    required this.onEnabledChanged,
    required this.onRequiredChanged,
  });

  final _AddonOption addon;
  final ValueChanged<bool>
      onEnabledChanged;
  final ValueChanged<bool>
      onRequiredChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.drag_indicator_rounded,
          color: AppColors.textDim,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                addon.name,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                '${addon.type} · ${addon.price}',
                style: const TextStyle(
                  color:
                      AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const Text(
          'Required',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),

        const SizedBox(width: 6),

        Switch(
          value: addon.required,
          onChanged:
              addon.enabled
              ? onRequiredChanged
              : null,
        ),

        const SizedBox(width: 12),

        Switch(
          value: addon.enabled,
          onChanged: onEnabledChanged,
        ),
      ],
    );
  }
}

class _AddonOption {
  const _AddonOption({
    required this.name,
    required this.type,
    required this.price,
    required this.enabled,
    required this.required,
  });

  final String name;
  final String type;
  final String price;
  final bool enabled;
  final bool required;

  _AddonOption copyWith({
    bool? enabled,
    bool? required,
  }) {
    return _AddonOption(
      name: name,
      type: type,
      price: price,
      enabled: enabled ?? this.enabled,
      required: required ?? this.required,
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        child,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  color:
                      AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ScheduleChoice extends StatelessWidget {
  const _ScheduleChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentSoft
              : AppColors.surface,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.accent
                : AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Icon(
                Icons.access_time_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.editing,
    required this.onCancel,
    required this.onDraft,
    required this.onPublish,
  });

  final bool editing;

  final VoidCallback onCancel;
  final VoidCallback onDraft;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.scaffold,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),

          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
              ),
            ),
          ),

          const SizedBox(width: 8),

          OutlinedButton(
            onPressed: onDraft,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  AppColors.accent,
              side: const BorderSide(
                color: AppColors.accent,
              ),
              minimumSize:
                  const Size(120, 44),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
            child: Text(
              editing
                  ? 'Save Changes'
                  : 'Save Draft',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),

          ElevatedButton(
            onPressed: onPublish,
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.accent,
              foregroundColor:
                  Colors.black,
              elevation: 0,
              minimumSize:
                  const Size(140, 44),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
            child: const Text(
              'Save & Publish',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
