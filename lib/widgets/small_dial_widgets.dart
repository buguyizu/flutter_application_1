part of '../clock_page.dart';

// Extension methods share the page State because the hover state stays in ClockPage.
// ignore_for_file: invalid_use_of_protected_member
extension _ClockPageSmallDials on _ClockPageState {
  Widget _buildYearDial(DateTime time) {
    final startYear = _yearCycleStart(time.year);
    final yearLabels = List<String>.generate(
      30,
      (index) => '${startYear + index}',
    );
    return MouseRegion(
      onExit: (_) => setState(() => _hoveredYearIndex = null),
      onHover: (event) {
        final index = dialIndexAt(event.localPosition, 30);
        if (index != _hoveredYearIndex) {
          setState(() => _hoveredYearIndex = index);
        }
      },
      child: SizedBox(
        width: 176,
        height: 210,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: ThirtySegmentDialPainter(
                  time.year - startYear,
                  title: _shiLabel(time.year),
                  labels: yearLabels,
                  labelIndices: List<int>.generate(30, (index) => index),
                  startAtBottom: true,
                  rotateLabels: true,
                  titleFontSize: 19,
                  currentLabelOffsetY: 12,
                  hoveredIndex: _hoveredYearIndex,
                  hoverLabel: _hoveredYearIndex == null
                      ? null
                      : _yearLabel(startYear + _hoveredYearIndex!),
                  currentLabel: _yearLabel(time.year),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF37474F),
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: _shiLabel(time.year),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: _localized('（30年）', ' (30 years)', '（30年）')),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBranchDial(DateTime time) {
    final huiIndex = _huangjiHuiIndex(time);
    final huiLabel = _huiLabel(time);
    return SizedBox(
      width: 176,
      height: 210,
      child: MouseRegion(
        onExit: (_) => setState(() => _hoveredBranchIndex = null),
        onHover: (event) {
          final index = dialIndexAt(event.localPosition, 12);
          if (index != _hoveredBranchIndex) {
            setState(() => _hoveredBranchIndex = index);
          }
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: BranchPlaceholderPainter(
                  _localized('日甲一元', 'Yuan 1', '日甲一元'),
                  huiIndex,
                  subtitle: huiLabel,
                  language: _language,
                  hoveredIndex: _hoveredBranchIndex,
                  hoverLabel: _hoveredBranchIndex == null
                      ? null
                      : _huiLabelForNumber(
                          _huangjiHuiNumber(time) +
                              (_hoveredBranchIndex! - huiIndex),
                        ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: Color(0xFF37474F), fontSize: 12),
                  children: [
                    TextSpan(
                      text: _localized('日甲一元', 'Yuan 1', '日甲一元'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: _localized(
                        '（12会-129600年）',
                        ' (12 Hui - 129,600 years)',
                        '（12会・129,600年）',
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThirtySegmentDial(DateTime time) {
    final currentIndex = _huangjiYunIndex(time);
    final huiLabel = _huiLabel(time);
    final firstYunNumber = _huangjiYunNumber(time) - currentIndex;
    final yunLabel = _yunLabel(time.year);
    final hoverLabel = _hoveredYunIndex == null
        ? null
        : _yunLabelForNumber(firstYunNumber + _hoveredYunIndex!);
    return SizedBox(
      width: 176,
      height: 210,
      child: MouseRegion(
        onExit: (_) => setState(() => _hoveredYunIndex = null),
        onHover: (event) {
          final index = dialIndexAt(event.localPosition, 30);
          if (index != _hoveredYunIndex) {
            setState(() => _hoveredYunIndex = index);
          }
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: ThirtySegmentDialPainter(
                  currentIndex,
                  title: huiLabel,
                  labels: List<String>.generate(
                    30,
                    (index) => '${firstYunNumber + index}',
                  ),
                  labelIndices: List<int>.generate(30, (index) => index),
                  startAtBottom: true,
                  hoveredIndex: _hoveredYunIndex,
                  hoverLabel: hoverLabel,
                  currentLabel: yunLabel,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: Color(0xFF37474F), fontSize: 12),
                  children: [
                    TextSpan(
                      text: huiLabel,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: _localized(
                        '（30运-10800年）',
                        ' (30 Yun - 10,800 years)',
                        '（30運・10,800年）',
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwelveSegmentDial(int currentIndex, int year) {
    final startYear = _yearCycleStart(year);
    return SizedBox(
      width: 176,
      height: 210,
      child: MouseRegion(
        onExit: (_) => setState(() => _hoveredShiIndex = null),
        onHover: (event) {
          final index = dialIndexAt(event.localPosition, 12);
          if (index != _hoveredShiIndex) {
            setState(() => _hoveredShiIndex = index);
          }
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: TwelveSegmentDialPainter(
                  currentIndex,
                  startYear,
                  language: _language,
                  title: _yunLabel(year),
                  subtitle: _shiLabel(year),
                  hoveredIndex: _hoveredShiIndex,
                  hoverLabel: _hoveredShiIndex == null
                      ? null
                      : _shiLabel(
                          year +
                              (_hoveredShiIndex! - currentIndex) *
                                  _ClockPageState._yearsPerShi,
                        ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF37474F),
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: _yunLabel(year),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: _localized(
                        '（12世-360年）',
                        ' (12 Shi - 360 years)',
                        '（12世・360年）',
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
