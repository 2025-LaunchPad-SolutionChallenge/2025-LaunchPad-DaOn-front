import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/common/widget/yellowBackButton.dart';
import 'package:project_daon/common/widget/Dropdwon.dart';
import 'package:project_daon/home/widget/semiCircleProgressBar.dart';
import 'package:project_daon/home/widget/homeAppBar.dart';
import 'package:project_daon/home/widget/startBlock.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _sheetPosition = 0.27;
  final double _minSheetSize = 0.27;
  final double _maxSheetSize = 0.77;

  @override
  Widget build(BuildContext context) {
    double dimOpacity =
        ((_sheetPosition - _minSheetSize) / (_maxSheetSize - _minSheetSize))
            .clamp(0.0, 1.0) *
        0.6;

    double screenHeight = MediaQuery.of(context).size.height;
    double bottomSheetHeight = screenHeight * _minSheetSize;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HomeAppBarWidget(),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.00, 0.00),
                end: Alignment(1.00, 0.71),
                colors: [ColorStyles.main2, ColorStyles.main3],
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomSheetHeight),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Dropdown(),
                    const SizedBox(height: 12.0),
                    StartBlock(name: "하은", myStep: "다시 움직이기"),

                    // 빈 공간을 꽉 채워서 자식들을 중앙으로 밀어주는 Expanded
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // 내부 요소들끼리 뭉치게 함
                          children: [
                            Image.asset('assets/home/exChar.png'),
                            const SizedBox(height: 20.0),
                            SemiCircleProgressBar(percentage: 0.48),
                            const SizedBox(height: 30.0),
                            YellowBackButton(
                              text: "오늘의 상태 체크",
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // [레이어 1.5] 🍀 배경이 검게 변하는 디밍(Dimming) 효과 레이어
          IgnorePointer(
            // 이 레이어 때문에 뒤에 있는 버튼 클릭이 막히지 않도록 합니다.
            child: Container(color: Colors.black.withOpacity(dimOpacity)),
          ),

          // [레이어 2] 🍀 드래그 가능한 하단 체크리스트 박스
          NotificationListener<DraggableScrollableNotification>(
            // 💡 6. 바텀 시트가 움직일 때마다 현재 높이를 업데이트하여 setState를 호출합니다.
            onNotification: (notification) {
              setState(() {
                _sheetPosition = notification.extent;
              });
              return true; // 이벤트 소비
            },
            child: DraggableScrollableSheet(
              initialChildSize: _minSheetSize,
              minChildSize: _minSheetSize,
              maxChildSize: _maxSheetSize,
              snap: true, // 스냅 설정
              builder:
                  (BuildContext context, ScrollController scrollController) {
                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: const ShapeDecoration(
                        color: ColorStyles.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(17),
                            topRight: Radius.circular(17),
                          ),
                        ),
                        shadows: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 75,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Text(
                                '오늘의 할 일',
                                style: FontStyles.semi16.copyWith(
                                  color: ColorStyles.black2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // 체크 리스트
                              Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: ColorStyles.main1,
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: ColorStyles.secon1,
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: ColorStyles.secon1,
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }
}
