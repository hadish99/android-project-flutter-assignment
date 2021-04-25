import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'dart:ui' as ui;
import 'authRepository.dart';
import 'home.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final biggerFont = const TextStyle(fontSize: 19.0);
  final _snapController = SnappingSheetController();
  final bottom_snap = SnappingPosition.factor(
    positionFactor: 0.0,
    snappingCurve: Curves.easeOutExpo,
    snappingDuration: Duration(seconds: 0),
    grabbingContentOffset: GrabbingContentOffset.top,
  );
  final mid_snap = SnappingPosition.pixels(
    positionPixels: 200,
    snappingCurve: Curves.elasticOut,
    grabbingContentOffset: GrabbingContentOffset.bottom,
  );
  final top_snap = SnappingPosition.factor(
    positionFactor: 0.9,
    snappingCurve: Curves.bounceOut,
    grabbingContentOffset: GrabbingContentOffset.top,
  );

  Widget _buildProfile(AuthRepository auth) {
    return Container(
        alignment: Alignment.center,
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible( fit:FlexFit.loose,
                child: Container(
                    width: 80,
                    height: 110,
                    alignment: Alignment.center,
                    child: auth.imgUrl != null ? Image.file(File(auth.imgUrl!)) : null,
                )
            ),

            Flexible(fit:FlexFit.loose,flex:2,
                child: Container(
                    child: ListView(shrinkWrap: true,
                      children: [
                      Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(auth.user!.email! ,textAlign: TextAlign.left ,style: biggerFont),
                          ]
                      ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.teal, // background
                              onPrimary: Colors.white, // foreground
                              alignment: Alignment.center,
                              shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                            ),
                            onPressed: () async {
                              PickedFile? result = await ImagePicker()
                                  .getImage(source: ImageSource.gallery);
                              if (result != null) {
                                await auth.updatePhoto(result.path);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('No image selected')));
                              }
                            },
                            child: Text('Change avatar')
                            ),
                          ]
                        )
                      ],
                    )))
          ],
        ));
  }

  bool finished_snapping = false;
  final no_blur = BackdropFilter(filter: ui.ImageFilter.blur());
  final blur = BackdropFilter(
    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    child: Container(color: Colors.black.withOpacity(0)),
  );


  @override
  Widget build(BuildContext context) {
    var bottomHeight = MediaQuery.of(context).viewInsets.bottom;
    AuthRepository _currentUser = Provider.of<AuthRepository>(context);
    return _currentUser.isAuthenticated
          ? Scaffold(
          body: SnappingSheet(
            controller: _snapController,
            grabbingHeight: 50,
            child: Stack(fit: StackFit.expand, children: [
              RandomWords(),
              //_snapController.currentPosition>0 ? blur : no_blur,
            ]),
            lockOverflowDrag: true,
            grabbing: Container(
                color: Colors.grey,
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _snapController.currentlySnapping
                            ? null
                            : _snapController.snapToPosition(bottom_snap);
                      });
                    },
                    child: Row(
                      children: [
                        Text('Welcome back, ${_currentUser.user!.email}',
                            style: biggerFont),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_up),
                      ],
                    )
                )
            ),
            sheetBelow: SnappingSheetContent(sizeBehavior: SheetSizeStatic(height:bottomHeight),
                draggable: true, child: _buildProfile(_currentUser)),
            snappingPositions: [
              bottom_snap,
              mid_snap,
              top_snap,
            ],
            onSnapCompleted: (double d,SnappingPosition snap){
              if(d>200){
                _snapController.snapToPosition(mid_snap);
              }
            },
          ))
          : RandomWords();
  }
}
