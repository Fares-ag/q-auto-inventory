import 'dart:typed_data';
import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/firestore_models.dart';

class QuarterlyReportService {
  // Cover page: black/white
  static const _brandPrimary = PdfColor.fromInt(0xFF000000);
  static const _brandPrimaryLight = PdfColor.fromInt(0xFF1A1A1A);
  static const _brandAccent = PdfColor.fromInt(0xFF404040);
  static const _white = PdfColors.white;

  // Content pages: distinct colors for sections, KPIs, charts
  static const _contentPrimary = PdfColor.fromInt(0xFF0F172A);
  static const _contentAccent = PdfColor.fromInt(0xFF0EA5E9);
  static const _contentTeal = PdfColor.fromInt(0xFF14B8A6);
  static const _contentGreen = PdfColor.fromInt(0xFF10B981);
  static const _contentAmber = PdfColor.fromInt(0xFFF59E0B);
  static const _contentPurple = PdfColor.fromInt(0xFF8B5CF6);
  static const _contentOrange = PdfColor.fromInt(0xFFF97316);
  static const _contentRed = PdfColor.fromInt(0xFFEF4444);
  static const _contentCyan = PdfColor.fromInt(0xFF06B6D4);

  static const _brandAccentLight = PdfColor.fromInt(0xFF737373);
  static const _grey50 = PdfColor.fromInt(0xFFFAFAFA);
  static const _grey100 = PdfColor.fromInt(0xFFF5F5F5);
  static const _grey200 = PdfColor.fromInt(0xFFE5E5E5);
  static const _grey400 = PdfColor.fromInt(0xFFA3A3A3);
  static const _grey500 = PdfColor.fromInt(0xFF737373);
  static const _grey600 = PdfColor.fromInt(0xFF475569);
  static const _grey700 = PdfColor.fromInt(0xFF334155);
  static const _grey900 = PdfColor.fromInt(0xFF0F172A);

  static const List<PdfColor> _chartPalette = [
    PdfColor.fromInt(0xFF0EA5E9),
    PdfColor.fromInt(0xFF14B8A6),
    PdfColor.fromInt(0xFF10B981),
    PdfColor.fromInt(0xFFF59E0B),
    PdfColor.fromInt(0xFF8B5CF6),
    PdfColor.fromInt(0xFFF97316),
    PdfColor.fromInt(0xFF06B6D4),
    PdfColor.fromInt(0xFFEF4444),
    PdfColor.fromInt(0xFF3B82F6),
    PdfColor.fromInt(0xFFEC4899),
  ];

  Future<Uint8List> buildQuarterlyReport({
    required List<InventoryItem> items,
    required List<Department> departments,
    required List<Category> categories,
    required int quarter,
    required int year,
    String companyName = 'Q Auto Inventory',
  }) async {
    final doc = pw.Document(
      title: 'Q$quarter $year Asset Report',
      author: companyName,
      creator: companyName,
    );

    final quarterMonths = _getQuarterMonths(quarter);
    final dateRange =
        '${quarterMonths.first} - ${quarterMonths.last} $year';
    final generatedDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

    // Map both id and name to display name so department column always shows names
    final deptMap = <String, String>{};
    for (final d in departments) {
      deptMap[d.id] = d.name;
      deptMap[d.name] = d.name;
    }
    final catMap = {for (final c in categories) c.id: c.name};

    final stats = _computeStats(items, deptMap, catMap);

    doc.addPage(_buildCoverPage(
      companyName: companyName,
      quarter: quarter,
      year: year,
      dateRange: dateRange,
      generatedDate: generatedDate,
      totalAssets: items.length,
    ));

    doc.addPage(_buildExecutiveSummaryPage(
      stats: stats,
      companyName: companyName,
      dateRange: dateRange,
      quarter: quarter,
      year: year,
    ));

    _addDistributionPages(
      doc: doc,
      stats: stats,
      companyName: companyName,
      quarter: quarter,
      year: year,
    );

    _addDetailPages(
      doc: doc,
      items: items,
      deptMap: deptMap,
      companyName: companyName,
      quarter: quarter,
      year: year,
    );

    doc.addPage(_buildClosingPage(
      companyName: companyName,
      generatedDate: generatedDate,
      quarter: quarter,
      year: year,
    ));

    return doc.save();
  }

  // ──────────────────────────────────────────────
  // COVER PAGE
  // ──────────────────────────────────────────────

  pw.Page _buildCoverPage({
    required String companyName,
    required int quarter,
    required int year,
    required String dateRange,
    required String generatedDate,
    required int totalAssets,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: [
            // Full-page dark background
            pw.Container(
              width: double.infinity,
              height: double.infinity,
              color: _brandPrimary,
            ),

            // Large decorative circle (top-right)
            pw.Positioned(
              top: -120,
              right: -80,
              child: pw.Container(
                width: 400,
                height: 400,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: _brandAccent.shade(0.15),
                ),
              ),
            ),

            // Medium circle (bottom-left)
            pw.Positioned(
              bottom: -60,
              left: -100,
              child: pw.Container(
                width: 300,
                height: 300,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: _brandPrimaryLight,
                ),
              ),
            ),

            // Small accent circle
            pw.Positioned(
              top: 300,
              left: 60,
              child: pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: _brandAccent.shade(0.25),
                ),
              ),
            ),

            // Teal accent bar at top
            pw.Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: pw.Container(
                height: 6,
                color: _brandAccent,
              ),
            ),

            // Content
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 60, vertical: 50),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 40),

                  // Company logo placeholder
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                          color: _brandAccent, width: 2),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 32,
                          height: 32,
                          color: _brandAccent,
                          child: pw.Center(
                            child: pw.Text(
                              'Q',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: _white,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          _sanitize(companyName).toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: _white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.Spacer(),

                  // Quarter badge
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: _brandAccent,
                      borderRadius: pw.BorderRadius.circular(24),
                    ),
                    child: pw.Text(
                      'Q$quarter $year',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: _white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Main title
                  pw.Text(
                    'Quarterly\nAsset Report',
                    style: pw.TextStyle(
                      fontSize: 52,
                      fontWeight: pw.FontWeight.bold,
                      color: _white,
                      lineSpacing: 4,
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // Teal divider line
                  pw.Container(
                    width: 80,
                    height: 4,
                    decoration: pw.BoxDecoration(
                      color: _brandAccent,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Subtitle
                  pw.Text(
                    'Comprehensive inventory analysis and asset tracking overview',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: _grey400,
                      lineSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _sanitize(dateRange),
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: _brandAccentLight,
                      letterSpacing: 0.5,
                    ),
                  ),

                  pw.Spacer(),

                  // Bottom info row
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: _brandPrimaryLight,
                      border: pw.Border.all(
                        color: PdfColor.fromInt(0xFF2D3A4F),
                        width: 1,
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        _coverInfoBlock(
                            'TOTAL ASSETS', _sanitize(totalAssets.toString())),
                        pw.SizedBox(width: 40),
                        _coverInfoBlock('GENERATED', _sanitize(generatedDate)),
                        pw.SizedBox(width: 40),
                        _coverInfoBlock(
                            'CLASSIFICATION', 'CONFIDENTIAL'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Widget _coverInfoBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: _grey500,
            letterSpacing: 1.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _sanitize(value),
          style: pw.TextStyle(
            fontSize: 13,
            color: _white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // EXECUTIVE SUMMARY
  // ──────────────────────────────────────────────

  pw.Page _buildExecutiveSummaryPage({
    required _ReportStats stats,
    required String companyName,
    required String dateRange,
    required int quarter,
    required int year,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('Executive Summary', 'Q$quarter $year', _sanitize(companyName)),
            pw.SizedBox(height: 8),
            pw.Text(
              _sanitize('A high-level overview of asset portfolio for $dateRange.'),
              style: pw.TextStyle(fontSize: 11, color: _grey600),
            ),
            pw.SizedBox(height: 24),

            // KPI cards row
            pw.Row(
              children: [
                _kpiCard('Total Assets', stats.total.toString(),
                    _contentPrimary, _contentAccent),
                pw.SizedBox(width: 10),
                _kpiCard('Active', stats.active.toString(),
                    _contentGreen, _contentGreen),
                pw.SizedBox(width: 10),
                _kpiCard('Assigned', stats.assigned.toString(),
                    _contentAccent, _contentAccent),
                pw.SizedBox(width: 10),
                _kpiCard('Written Off', stats.writtenOff.toString(),
                    _contentRed, _contentRed),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              children: [
                _kpiCard('Departments', stats.departmentCount.toString(),
                    _contentPurple, _contentPurple),
                pw.SizedBox(width: 10),
                _kpiCard('Categories', stats.categoryCount.toString(),
                    _contentOrange, _contentOrange),
                pw.SizedBox(width: 10),
                _kpiCard(
                    'Total Value',
                    _sanitize(_formatCurrency(stats.totalValue)),
                    _contentTeal,
                    _contentTeal),
                pw.SizedBox(width: 10),
                _kpiCard('Avg. Value', _sanitize(_formatCurrency(stats.avgValue)),
                    _contentCyan, _contentCyan),
              ],
            ),

            pw.SizedBox(height: 28),

            // Status breakdown
            _sectionTitle('Asset Status Breakdown'),
            pw.SizedBox(height: 12),
            _statusBreakdownTable(stats),

            pw.SizedBox(height: 28),

            // Asset types breakdown (merge small categories so chart is meaningful)
            if (stats.assetTypeBreakdown.isNotEmpty) ...[
              _sectionTitle('Asset Type Distribution'),
              pw.SizedBox(height: 12),
              _horizontalBarChart(
                _mergeSmallCategories(
                    stats.assetTypeBreakdown, stats.total,
                    pctThreshold: 1.0),
                stats.total,
              ),
            ],

            pw.Spacer(),
            _pageFooter(context, companyName, quarter, year),
          ],
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // DISTRIBUTION PAGE
  // ──────────────────────────────────────────────

  void _addDistributionPages({
    required pw.Document doc,
    required _ReportStats stats,
    required String companyName,
    required int quarter,
    required int year,
  }) {
    final deptEntries = stats.departmentBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const int deptsPerFirstPage = 16;
    const int deptsPerContPage = 22;

    final List<List<MapEntry<String, int>>> deptChunks = [];
    int offset = 0;
    while (offset < deptEntries.length) {
      final limit = deptChunks.isEmpty ? deptsPerFirstPage : deptsPerContPage;
      final end = math.min(offset + limit, deptEntries.length);
      deptChunks.add(deptEntries.sublist(offset, end));
      offset = end;
    }
    if (deptChunks.isEmpty) deptChunks.add([]);

    for (int page = 0; page < deptChunks.length; page++) {
      final isFirst = page == 0;
      final chunk = deptChunks[page];
      final globalOffset = isFirst ? 0 : deptsPerFirstPage + (page - 1) * deptsPerContPage;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (isFirst)
                  _pageHeader(
                      'Asset Distribution', 'Q$quarter $year', companyName)
                else
                  _pageHeader(
                      'Asset Distribution (cont.)', 'Q$quarter $year', companyName),
                pw.SizedBox(height: isFirst ? 24 : 12),
                if (isFirst) _sectionTitle('By Department'),
                if (isFirst) pw.SizedBox(height: 12),
                _departmentTableChunk(chunk, stats.total, globalOffset),
                pw.Spacer(),
                _pageFooter(context, companyName, quarter, year),
              ],
            );
          },
        ),
      );
    }

    if (stats.categoryBreakdown.isNotEmpty) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pageHeader(
                    'Category Distribution', 'Q$quarter $year', companyName),
                pw.SizedBox(height: 24),
                _sectionTitle('By Category'),
                pw.SizedBox(height: 12),
                _horizontalBarChart(
                  _mergeSmallCategories(
                      stats.categoryBreakdown, stats.total,
                      pctThreshold: 1.0),
                  stats.total,
                ),
                pw.Spacer(),
                _pageFooter(context, companyName, quarter, year),
              ],
            );
          },
        ),
      );
    }
  }

  // ──────────────────────────────────────────────
  // DETAIL PAGES
  // ──────────────────────────────────────────────

  void _addDetailPages({
    required pw.Document doc,
    required List<InventoryItem> items,
    required Map<String, String> deptMap,
    required String companyName,
    required int quarter,
    required int year,
  }) {
    const int firstPageRows = 20;
    const int contPageRows = 25;

    final tableHeaders = [
      'Asset ID',
      'SAP ID',
      'Name',
      'Department',
      'Status',
      'Assigned To',
      'Value (QAR)',
    ];

    final sortedItems = List<InventoryItem>.from(items)
      ..sort((a, b) {
        final deptCmp = a.departmentId.compareTo(b.departmentId);
        if (deptCmp != 0) return deptCmp;
        return a.assetId.compareTo(b.assetId);
      });

    final allRows = sortedItems.asMap().entries.map((e) {
      final item = e.value;
      final deptRaw = deptMap[item.departmentId] ?? item.departmentId;
      final deptDisplay = (deptRaw.toString().trim().isEmpty) ? '-' : deptRaw;
      final sapId = _generateSapId(item.assetId, e.key);
      return [
        _sanitize(item.assetId),
        sapId,
        _sanitize(_truncate(item.name, 24)),
        _sanitize(_truncate(deptDisplay, 20)),
        _sanitize((item.status ?? '-').toUpperCase()),
        _sanitize(_truncate(item.assignedTo ?? '-', 16)),
        item.purchasePrice != null
            ? _sanitize(_formatCurrency(item.purchasePrice!))
            : '-',
      ];
    }).toList();

    if (allRows.isEmpty) return;

    final List<List<List<String>>> chunks = [];
    int offset = 0;
    while (offset < allRows.length) {
      final limit = chunks.isEmpty ? firstPageRows : contPageRows;
      final end = math.min(offset + limit, allRows.length);
      chunks.add(allRows.sublist(offset, end));
      offset = end;
    }

    for (int page = 0; page < chunks.length; page++) {
      final chunk = chunks[page];
      if (chunk.isEmpty) continue;
      final isFirst = page == 0;
      final isLast = page == chunks.length - 1;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (isFirst)
                  _pageHeader(
                      'Detailed Asset Register', 'Q$quarter $year', companyName)
                else
                  _pageHeader('Asset Register (cont.)',
                      'Q$quarter $year', companyName),
                pw.SizedBox(height: isFirst ? 16 : 10),
                if (isFirst)
                  pw.Text(
                    'Complete listing of all ${items.length} assets sorted by department.',
                    style: pw.TextStyle(fontSize: 10, color: _grey600),
                  ),
                if (isFirst) pw.SizedBox(height: 12),
                _styledTable(tableHeaders, chunk),
                if (isLast) ...[
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: _grey50,
                      border: pw.Border.all(color: _grey200),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          'Total Assets: ${items.length}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _brandPrimary,
                          ),
                        ),
                        pw.Spacer(),
                        pw.Text(
                          'End of Asset Register',
                          style: pw.TextStyle(
                              fontSize: 9, color: _grey500),
                        ),
                      ],
                    ),
                  ),
                ],
                pw.Spacer(),
                _pageFooter(context, companyName, quarter, year),
              ],
            );
          },
        ),
      );
    }
  }

  // ──────────────────────────────────────────────
  // CLOSING PAGE
  // ──────────────────────────────────────────────

  pw.Page _buildClosingPage({
    required String companyName,
    required String generatedDate,
    required int quarter,
    required int year,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: [
            pw.Container(
              width: double.infinity,
              height: double.infinity,
              color: _brandPrimary,
            ),

            pw.Positioned(
              bottom: -80,
              right: -60,
              child: pw.Container(
                width: 350,
                height: 350,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: _brandPrimaryLight,
                ),
              ),
            ),
            pw.Positioned(
              top: -40,
              left: -80,
              child: pw.Container(
                width: 220,
                height: 220,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: _brandAccent.shade(0.15),
                ),
              ),
            ),

            pw.Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: pw.Container(height: 6, color: _brandAccent),
            ),

            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 60, vertical: 50),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Spacer(flex: 2),

                  pw.Container(
                    width: 60,
                    height: 4,
                    decoration: pw.BoxDecoration(
                      color: _brandAccent,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  pw.Text(
                    'End of Report',
                    style: pw.TextStyle(
                      fontSize: 36,
                      fontWeight: pw.FontWeight.bold,
                      color: _white,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Q$quarter $year Quarterly Asset Report',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: _brandAccentLight,
                    ),
                  ),
                  pw.SizedBox(height: 30),

                  pw.Container(
                    width: double.infinity,
                    height: 1,
                    color: PdfColor.fromInt(0xFF2D3A4F),
                  ),
                  pw.SizedBox(height: 30),

                  _closingInfoRow('Prepared By', companyName),
                  pw.SizedBox(height: 14),
                  _closingInfoRow('Report Date', generatedDate),
                  pw.SizedBox(height: 14),
                  _closingInfoRow('Period',
                      _sanitize('${_getQuarterMonths(quarter).first} - ${_getQuarterMonths(quarter).last} $year')),
                  pw.SizedBox(height: 14),
                  _closingInfoRow('Classification', 'Confidential'),

                  pw.Spacer(flex: 2),

                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColor.fromInt(0xFF2D3A4F),
                      ),
                    ),
                    child: pw.Text(
                      'This document contains confidential information. '
                      'Distribution is limited to authorized personnel only. '
                      'Do not reproduce without written consent.',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: _grey500,
                        lineSpacing: 3,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Widget _closingInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: _grey500,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        pw.Text(
          _sanitize(value),
          style: pw.TextStyle(
            fontSize: 12,
            color: _white,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // SHARED WIDGETS
  // ──────────────────────────────────────────────

  pw.Widget _pageHeader(
      String title, String quarterLabel, String companyName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitize(title),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _contentPrimary,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: pw.BoxDecoration(
                color: _contentAccent,
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Text(
                _sanitize(quarterLabel),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _white,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          height: 2,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [_contentAccent, _contentTeal],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pageFooter(
      pw.Context context, String companyName, int quarter, int year) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _grey200, width: 1)),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            _sanitize('$companyName  |  Q$quarter $year Quarterly Report'),
            style: pw.TextStyle(fontSize: 8, color: _grey500),
          ),
          pw.Spacer(),
          pw.Text(
            'CONFIDENTIAL',
            style: pw.TextStyle(
              fontSize: 7,
              color: _grey400,
              letterSpacing: 1.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 18,
          decoration: pw.BoxDecoration(
            color: _contentAccent,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _contentPrimary,
          ),
        ),
      ],
    );
  }

  pw.Widget _kpiCard(
      String label, String value, PdfColor bgColor, PdfColor accentColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: _grey50,
          border: pw.Border(
            left: pw.BorderSide(color: accentColor, width: 3),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: _grey500,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: bgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _statusBreakdownTable(_ReportStats stats) {
    final entries = stats.statusBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final statusColors = <String, PdfColor>{
      'active': _contentGreen,
      'available': _contentGreen,
      'assigned': _contentAccent,
      'maintenance': _contentAmber,
      'pending': _contentOrange,
      'retired': _grey500,
      'inactive': _grey400,
      'written off': _contentRed,
    };

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grey200),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            color: _grey100,
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text('Status',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _grey700)),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text('Count',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _grey700)),
                ),
                pw.Expanded(
                  flex: 5,
                  child: pw.Text('Distribution',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _grey700)),
                ),
              ],
            ),
          ),
          ...entries.take(8).toList().asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              final pct = stats.total > 0
                  ? (entry.value / stats.total * 100)
                  : 0.0;
              final color = statusColors[entry.key.toLowerCase()] ?? _grey400;

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                color: idx.isEven ? _white : _grey50,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 8,
                          height: 8,
                          decoration: pw.BoxDecoration(
                            color: color,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          _sanitize(_capitalize(entry.key)),
                          style: pw.TextStyle(
                              fontSize: 9, color: _grey900),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '${entry.value}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _grey900,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 5,
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Stack(
                            children: [
                              pw.Container(
                                height: 10,
                                decoration: pw.BoxDecoration(
                                  color: _grey100,
                                  borderRadius:
                                      pw.BorderRadius.circular(5),
                                ),
                              ),
                              pw.Container(
                                height: 10,
                                width: pct * 1.8,
                                decoration: pw.BoxDecoration(
                                  color: color,
                                  borderRadius:
                                      pw.BorderRadius.circular(5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                              fontSize: 8, color: _grey600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _departmentTableChunk(
      List<MapEntry<String, int>> entries, int total, int colorOffset) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grey200),
      ),
      child: pw.Column(
        children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              color: _contentPrimary,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('Department',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _white)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Assets',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _white)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('% of Total',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _white)),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('Distribution',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _white)),
                  ),
                ],
              ),
            ),
            ...entries.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              final pct = total > 0
                  ? (entry.value / total * 100)
                  : 0.0;
              final color =
                  _chartPalette[(idx + colorOffset) % _chartPalette.length];

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                color: idx.isEven ? _white : _grey50,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 10,
                            height: 10,
                            decoration: pw.BoxDecoration(
                              color: color,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: pw.Text(
                              _sanitize(entry.key),
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: _grey900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '${entry.value}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _grey900,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                            fontSize: 9, color: _grey600),
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Stack(
                        children: [
                          pw.Container(
                            height: 10,
                            decoration: pw.BoxDecoration(
                              color: _grey100,
                              borderRadius: pw.BorderRadius.circular(5),
                            ),
                          ),
                          pw.Container(
                            height: 10,
                            width: pct * 1.5,
                            decoration: pw.BoxDecoration(
                              color: color,
                              borderRadius: pw.BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
    );
  }

  pw.Widget _horizontalBarChart(
      Map<String, int> data, int total) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount =
        entries.isNotEmpty ? entries.first.value : 1;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grey200),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Column(
        children: entries.take(10).toList().asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          final ratio = maxCount > 0 ? entry.value / maxCount : 0.0;
          final pct = total > 0 ? (entry.value / total * 100) : 0.0;
          final color = _chartPalette[idx % _chartPalette.length];

          final pctText = pct >= 1
              ? '${pct.toStringAsFixed(0)}%'
              : (pct > 0 ? '<1%' : '0%');
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 100,
                  child: pw.Text(
                    _truncate(_sanitize(entry.key), 16),
                    style: pw.TextStyle(
                        fontSize: 8, color: _grey700),
                  ),
                ),
                pw.Expanded(
                  child: pw.LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth =
                          (constraints?.maxWidth ?? 200) *
                              ratio.clamp(0.02, 1.0);
                      return pw.Stack(
                        children: [
                          pw.Container(
                            height: 14,
                            decoration: pw.BoxDecoration(
                              color: _grey100,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                          pw.Container(
                            height: 14,
                            width: barWidth,
                            decoration: pw.BoxDecoration(
                              color: color,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 50,
                  child: pw.Text(
                    '${entry.value} ($pctText)',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _grey700,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _styledTable(
      List<String> headers, List<List<String>> rows) {
    return pw.Table(
        border: pw.TableBorder(
          horizontalInside: const pw.BorderSide(
            color: _grey200,
            width: 0.5,
          ),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1.8),
          2: const pw.FlexColumnWidth(3),
          3: const pw.FlexColumnWidth(2.8),
          4: const pw.FlexColumnWidth(1.6),
          5: const pw.FlexColumnWidth(2.2),
          6: const pw.FlexColumnWidth(1.8),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _contentPrimary),
            children: headers.map((h) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 7),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _white,
                  ),
                ),
              );
            }).toList(),
          ),
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: idx.isEven ? _white : _grey50,
              ),
              children: row.asMap().entries.map((cell) {
                final isStatus = cell.key == 4;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  child: isStatus
                      ? _statusBadge(cell.value)
                      : pw.Text(
                          _sanitize(cell.value),
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: _grey900,
                          ),
                        ),
                );
              }).toList(),
            );
          }),
        ],
    );
  }

  pw.Widget _statusBadge(String status) {
    final statusColors = <String, PdfColor>{
      'ACTIVE': _contentGreen,
      'AVAILABLE': _contentGreen,
      'ASSIGNED': _contentAccent,
      'MAINTENANCE': _contentAmber,
      'PENDING': _contentOrange,
      'RETIRED': _grey500,
      'INACTIVE': _grey400,
      'WRITTEN OFF': _contentRed,
    };
    final color = statusColors[status.toUpperCase()] ?? _grey500;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        _sanitize(status),
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // STATS COMPUTATION
  // ──────────────────────────────────────────────

  _ReportStats _computeStats(List<InventoryItem> items,
      Map<String, String> deptMap, Map<String, String> catMap) {
    final statusMap = <String, int>{};
    final deptBreakdown = <String, int>{};
    final catBreakdown = <String, int>{};
    final typeBreakdown = <String, int>{};
    int active = 0;
    int assigned = 0;
    int writtenOff = 0;
    double totalValue = 0;
    int valuedCount = 0;

    for (final item in items) {
      final status = _sanitize(_capitalize(item.status ?? 'Unknown'));
      statusMap[status] = (statusMap[status] ?? 0) + 1;

      final deptRaw = deptMap[item.departmentId] ?? item.departmentId;
      final deptName = _sanitize(deptRaw.toString().trim().isEmpty ? '-' : deptRaw);
      deptBreakdown[deptName] = (deptBreakdown[deptName] ?? 0) + 1;

      final catRaw = catMap[item.categoryId] ?? item.categoryId;
      final catName = _sanitize(catRaw.isEmpty ? '-' : catRaw);
      catBreakdown[catName] = (catBreakdown[catName] ?? 0) + 1;

      final rawType = (item.assetType ?? item.itemType ?? '').toString().trim();
      final type = rawType.isEmpty || _isGenericType(rawType)
          ? 'Other / Unspecified'
          : _sanitize(rawType);
      typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;

      if (item.status?.toLowerCase() == 'active' ||
          item.status?.toLowerCase() == 'available') {
        active++;
      }
      if (item.assignedTo != null && item.assignedTo!.isNotEmpty) {
        assigned++;
      }
      if (item.isWrittenOff == true) {
        writtenOff++;
      }
      if (item.purchasePrice != null) {
        totalValue += item.purchasePrice!;
        valuedCount++;
      }
    }

    final uniqueDepts = deptBreakdown.keys.toSet();
    final uniqueCats = catBreakdown.keys.toSet();

    return _ReportStats(
      total: items.length,
      active: active,
      assigned: assigned,
      writtenOff: writtenOff,
      totalValue: totalValue,
      avgValue: valuedCount > 0 ? totalValue / valuedCount : 0,
      departmentCount: uniqueDepts.length,
      categoryCount: uniqueCats.length,
      statusBreakdown: statusMap,
      departmentBreakdown: deptBreakdown,
      categoryBreakdown: catBreakdown,
      assetTypeBreakdown: typeBreakdown,
    );
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  List<String> _getQuarterMonths(int quarter) {
    switch (quarter) {
      case 1:
        return ['January', 'February', 'March'];
      case 2:
        return ['April', 'May', 'June'];
      case 3:
        return ['July', 'August', 'September'];
      case 4:
        return ['October', 'November', 'December'];
      default:
        return ['January', 'February', 'March'];
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static bool _isGenericType(String s) {
    final lower = s.toLowerCase();
    return lower == 'other' ||
        lower == 'unspecified' ||
        lower == 'n/a' ||
        lower == 'na' ||
        lower.startsWith('n/a');
  }

  /// Merge categories with share below [pctThreshold]% into "Other (misc)" for clearer charts.
  static Map<String, int> _mergeSmallCategories(
      Map<String, int> breakdown, int total,
      {double pctThreshold = 1.0}) {
    if (total <= 0 || breakdown.isEmpty) return breakdown;
    final result = <String, int>{};
    int miscCount = 0;
    for (final e in breakdown.entries) {
      final pct = e.value / total * 100;
      if (pct >= pctThreshold) {
        result[e.key] = e.value;
      } else {
        miscCount += e.value;
      }
    }
    if (miscCount > 0) {
      result['Other (misc)'] = miscCount;
    }
    return result;
  }

  /// Keep only ASCII printable (32-126) so the PDF never shows replacement/symbol glyphs.
  static String _sanitize(String s) {
    if (s.isEmpty) return s;
    final sb = StringBuffer();
    for (final rune in s.runes) {
      if (rune >= 32 && rune <= 126) {
        sb.writeCharCode(rune);
      }
    }
    final out = sb.toString().trim();
    return out.isEmpty ? '-' : out;
  }

  static String _generateSapId(String assetId, int index) {
    final digits = assetId.replaceAll(RegExp(r'[^0-9]'), '');
    final seed = digits.isNotEmpty ? int.tryParse(digits) ?? index : index;
    final sapNum = 30000000 + seed;
    return sapNum.toString();
  }

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen - 3)}...';
  }

  static String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'QAR ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'QAR ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'QAR ${value.toStringAsFixed(0)}';
  }
}

class _ReportStats {
  const _ReportStats({
    required this.total,
    required this.active,
    required this.assigned,
    required this.writtenOff,
    required this.totalValue,
    required this.avgValue,
    required this.departmentCount,
    required this.categoryCount,
    required this.statusBreakdown,
    required this.departmentBreakdown,
    required this.categoryBreakdown,
    required this.assetTypeBreakdown,
  });

  final int total;
  final int active;
  final int assigned;
  final int writtenOff;
  final double totalValue;
  final double avgValue;
  final int departmentCount;
  final int categoryCount;
  final Map<String, int> statusBreakdown;
  final Map<String, int> departmentBreakdown;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> assetTypeBreakdown;
}
