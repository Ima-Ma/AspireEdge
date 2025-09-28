// cv_builder_pro.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:aspire_edge/UserScreens/UserComponents/appbar.dart';
import 'package:aspire_edge/UserScreens/UserComponents/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gga;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

/// A full-featured CV builder page:
/// - Stepper with Profile / Education / Experience / Skills / Template
/// - Gemini AI suggestions (safe, with fallback)
/// - Template carousel with miniature previews (no overflow)
/// - Portfolio multi-image upload + preview
/// - Color picker for CV accent color
/// - PDF preview & download
class CVTips extends StatefulWidget {
  const CVTips({Key? key}) : super(key: key);

  @override
  State<CVTips> createState() => _CVTipsState();
}

class _CVTipsState extends State<CVTips> {
  // Stepper
  int _currentStep = 0;
  // Template selection 0..4
  int _selectedTemplate = 0;

  // User data controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _summaryCtrl = TextEditingController();

  final TextEditingController _eduCtrl = TextEditingController();
  final TextEditingController _expCtrl = TextEditingController();
  final TextEditingController _skillCtrl = TextEditingController();

  final List<String> _education = [];
  final List<String> _experience = [];
  final List<String> _skills = [];

  // Portfolio images stored as bytes
  List<Uint8List> _portfolioImages = [];

  // Accent color for CV
  Color _accentColor = Color(0xFF6C95DA);

  // Gemini config (replace with your key; in production call your backend)
  static const String GEMINI_API_KEY = "AIzaSyBlQdCsngesteT7E96BKv0ttMg_8m3sLKA"; // <<-- put your key here OR keep empty to use fallback
  late final gga.GenerativeModel? _genModel;

  @override
  void initState() {
    super.initState();
    // initialize generative model if key present; wrap in try/catch to avoid runtime issues
    if (GEMINI_API_KEY.trim().isNotEmpty) {
      try {
        _genModel = gga.GenerativeModel(model: 'gemini-1.5', apiKey: GEMINI_API_KEY);
      } catch (e) {
        // If package API changes or import fails, fallback to null
        debugPrint("GenerativeModel init error: $e");
        _genModel = null;
      }
    } else {
      _genModel = null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _eduCtrl.dispose();
    _expCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  // -----------------------
  // AI Suggestion (Gemini or fallback)
  // -----------------------
  Future<String> _aiImprove(String input, String sectionHint) async {
    final prompt = "Improve this $sectionHint for a CV. Make it concise, professional and results-focused: $input";

    // If there's no model instance, return local fallback
    if (_genModel == null) {
      return _localFallback(input, sectionHint);
    }

    try {
      // Use dynamic call and defensively extract text; the package may have evolving response shapes.
      final resp = await _genModel!.generateContent([gga.Content.text(prompt)]);
      // Try several possible shapes to extract text safely
      try {
        // common property `text`
        final maybeText = (resp as dynamic).text;
        if (maybeText != null && maybeText.toString().trim().isNotEmpty) {
          return maybeText.toString().trim();
        }
      } catch (_) {}

      // try candidates list with nested structures
      try {
        final cand = (resp as dynamic).candidates;
        if (cand != null && cand is List && cand.isNotEmpty) {
          final first = cand[0];
          // try common fields
          final poss =
              (first as dynamic).content?.text ?? (first as dynamic).output ?? (first as dynamic).text ?? (first as dynamic).message ?? null;
          if (poss != null && poss.toString().trim().isNotEmpty) return poss.toString().trim();
        }
      } catch (_) {}

      // fallback on resp.toString()
      final s = resp.toString();
      if (s.isNotEmpty) return s;
      return _localFallback(input, sectionHint);
    } catch (e) {
      debugPrint("Gemini call failed: $e");
      return _localFallback(input, sectionHint);
    }
  }

  // Local, helpful fallback if AI key missing or call fails
  String _localFallback(String input, String section) {
    if (input.trim().isEmpty) {
      switch (section) {
        case 'summary':
          return "Motivated professional with strong background; show 1–2 specific achievements and a target role.";
        case 'education':
          return "Format: Degree, University — Year. Add honors/CGPA if relevant.";
        case 'experience':
          return "Start each bullet with an action verb, include results (numbers/impact).";
        case 'skill':
        default:
          return "Group skills by category (Languages, Frameworks, Tools). Use commas.";
      }
    }

    // small heuristic transform
    if (section == 'summary') {
      final firstSentence = input.split('.').first;
      return "${firstSentence.trim()}. Proven ability to deliver measurable results.";
    } else if (section == 'experience') {
      return "Led initiatives and improved outcomes. Example (improve text): $input";
    } else if (section == 'education') {
      return "Degree and institution first. Example: $input";
    } else if (section == 'skill') {
      return "Grouped: ${input.replaceAll(',', ' • ')}";
    }
    return input;
  }

  // -----------------------
  // File picker for multi images
  // -----------------------
  Future<void> _pickPortfolioImages() async {
    try {
      final res = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image, withData: true);
      if (res != null && res.files.isNotEmpty) {
        setState(() {
          // keep those with bytes
          _portfolioImages.addAll(res.files.where((f) => f.bytes != null).map((f) => f.bytes!).toList());
        });
      }
    } catch (e) {
      debugPrint("File pick error: $e");
    }
  }

  // -----------------------
  // PDF generation using selected template + accent color + portfolio
  // -----------------------
  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final name = _nameCtrl.text.trim().isEmpty ? "Your Name" : _nameCtrl.text.trim();
    final title = _titleCtrl.text.trim().isEmpty ? "Job Title" : _titleCtrl.text.trim();
    final summary = _summaryCtrl.text.trim();

    final pdfAccent = PdfColor.fromInt(_accentColor.value);

    // create page generator for selected template
    switch (_selectedTemplate) {
      case 0:
        pdf.addPage(_pdfTemplateModern(name, title, summary, pdfAccent));
        break;
      case 1:
        pdf.addPage(_pdfTemplateCorporate(name, title, summary, pdfAccent));
        break;
      case 2:
        pdf.addPage(_pdfTemplateCreative(name, title, summary, pdfAccent));
        break;
      case 3:
        pdf.addPage(_pdfTemplateMinimal(name, title, summary, pdfAccent));
        break;
      case 4:
      default:
        pdf.addPage(_pdfTemplateElegant(name, title, summary, pdfAccent));
        break;
    }

    // optionally add a second page with portfolio thumbnails
    if (_portfolioImages.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          final imgs = _portfolioImages.map((b) => pw.MemoryImage(b)).toList();
          return [
            pw.Header(level: 1, child: pw.Text("Portfolio", style: pw.TextStyle(color: pdfAccent, fontSize: 18))),
            pw.Wrap(spacing: 8, runSpacing: 8, children: imgs.map((im) => pw.Container(width: 160, height: 120, child: pw.Image(im, fit: pw.BoxFit.cover))).toList())
          ];
        },
      ));
    }

    return pdf.save();
  }

  // Helper templates (simple but visually distinct)
  pw.Page _pdfTemplateModern(String name, String title, String summary, PdfColor accent) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.all(26),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(name, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: accent)),
              pw.Text(title, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            ]),
            pw.Container(width: 90, height: 90, decoration: pw.BoxDecoration(), child: pw.Center(child: pw.Text("PHOTO"))),
          ]),
          pw.SizedBox(height: 12),
          pw.Text("Profile", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent)),
          pw.Text(summary),
          pw.SizedBox(height: 8),
          pw.Text("Education", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent)),
          ..._education.map((e) => pw.Bullet(text: e)),
          pw.SizedBox(height: 6),
          pw.Text("Experience", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent)),
          ..._experience.map((e) => pw.Bullet(text: e)),
          pw.SizedBox(height: 6),
          pw.Text("Skills", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent)),
          pw.Wrap(spacing: 6, children: _skills.map((s) => pw.Container(padding: const pw.EdgeInsets.all(4), decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(4), color: PdfColors.grey200), child: pw.Text(s))).toList())
        ]),
      ),
    );
  }

  pw.Page _pdfTemplateCorporate(String name, String title, String summary, PdfColor accent) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(children: [
        pw.Container(height: 100, color: accent, padding: const pw.EdgeInsets.all(12), child: pw.Center(child: pw.Column(children: [pw.Text(name, style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)), pw.Text(title, style: pw.TextStyle(color: PdfColors.white))]))),
        pw.Padding(padding: const pw.EdgeInsets.all(16), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text("Profile", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(summary),
          pw.Divider(),
          pw.Text("Education", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ..._education.map((e) => pw.Text("• $e")),
          pw.SizedBox(height: 6),
          pw.Text("Experience", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ..._experience.map((e) => pw.Text("• $e")),
          pw.SizedBox(height: 6),
          pw.Text("Skills", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_skills.join(", ")),
        ]))
      ]),
    );
  }

  pw.Page _pdfTemplateCreative(String name, String title, String summary, PdfColor accent) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) =>  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Text(name, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: accent)),
        pw.Text(title, style: pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.Text(summary, textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 10),
        pw.Text("Education", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
        ..._education.map((e) => pw.Text(e)),
        pw.SizedBox(height: 6),
        pw.Text("Experience", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
        ..._experience.map((e) => pw.Text(e)),
        pw.SizedBox(height: 6),
        pw.Text("Skills", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Wrap(children: _skills.map((s) => pw.Container(padding: const pw.EdgeInsets.all(3), margin: const pw.EdgeInsets.all(2), decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(3), color: PdfColors.grey200), child: pw.Text(s))).toList())
      ]));
  }

  pw.Page _pdfTemplateMinimal(String name, String title, String summary, PdfColor accent) {
    return pw.Page(pageFormat: PdfPageFormat.a4, build: (ctx) =>  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.Text(title, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
      pw.Divider(),
      pw.Text(summary),
      pw.SizedBox(height: 10),
      pw.Text("Education: ${_education.join(' • ')}"),
      pw.Text("Experience: ${_experience.join(' • ')}"),
      pw.Text("Skills: ${_skills.join(', ')}"),
    ]));
  }

  pw.Page _pdfTemplateElegant(String name, String title, String summary, PdfColor accent) {
    return pw.Page(pageFormat: PdfPageFormat.a4, build: (ctx) => pw.Column(children: [
      pw.Center(child: pw.Text(name, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: accent))),
      pw.SizedBox(height: 6),
      pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 12))),
      pw.Divider(),
      pw.Text("Profile", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text(summary),
      pw.SizedBox(height: 8),
      pw.Text("Education", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ..._education.map((e) => pw.Text("• $e")),
      pw.SizedBox(height: 6),
      pw.Text("Experience", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ..._experience.map((e) => pw.Text("• $e")),
      pw.SizedBox(height: 6),
      pw.Text("Skills", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text(_skills.join(", ")),
    ]));
  }

  // -----------------------
  // Thumbnail widgets (mini-cv previews)
  // -----------------------
  Widget _templateThumb(int index, bool selected) {
    final w = 140.0;
    final h = 200.0;
    final border = selected ? Border.all(color: _accentColor, width: 2) : Border.all(color: Colors.grey.shade300, width: 1);
    final sampleName = "John Doe";
    final sampleTitle = "Mobile Developer";
    final sampleSummary = "Creative dev focusing on cross-platform mobile apps.";
    final sampleSkills = ["Flutter"];

    switch (index) {
      case 0:
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: border, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sampleName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sampleTitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const Divider(),
            Text(sampleSummary, style: const TextStyle(fontSize: 11), maxLines: 4, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Wrap(spacing: 4, children: sampleSkills.map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.grey.shade200), child: Text(s, style: const TextStyle(fontSize: 10)))).toList()),
          ]),
        );
      case 1:
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: border),
          padding: const EdgeInsets.all(6),
          child: Column(children: [
            Container(width: double.infinity, color: Colors.blue.shade700, padding: const EdgeInsets.all(6), child: Center(child: Text(sampleName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 6),
            Text(sampleTitle, style: const TextStyle(fontSize: 11)),
            const Divider(),
            Text(sampleSummary, maxLines: 5, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          ]),
        );
      case 2:
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: border),
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Text(sampleName, style: TextStyle(fontWeight: FontWeight.bold, color: _accentColor)),
            Text(sampleTitle, style: const TextStyle(fontSize: 11)),
            const Divider(),
            Text(sampleSummary, textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: sampleSkills.map((s) => Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Chip(label: Text(s, style: const TextStyle(fontSize: 10))))).toList())
          ]),
        );
      case 3:
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(border: border, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sampleName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sampleTitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const Divider(),
            Text(sampleSummary, style: const TextStyle(fontSize: 11)),
          ]),
        );
      case 4:
      default:
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: border),
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Center(child: Text(sampleName, style: TextStyle(fontWeight: FontWeight.bold, color: _accentColor))),
            const SizedBox(height: 6),
            Text(sampleTitle),
            const Divider(),
            Text(sampleSummary, maxLines: 4, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: sampleSkills.map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.grey.shade200), child: Text(s, style: const TextStyle(fontSize: 10)))).toList()),
          ]),
        );
    }
  }

  // -----------------------
  // UI
  // -----------------------
 @override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    appBar: AspireAppBar(),

    body: SingleChildScrollView(
      child: Column(
        children: [
          // ---------- Header Section with Stack ----------
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: screenHeight * 0.35,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/cv.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Aspire Edge 🎯",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        textStyle: const TextStyle(
                          fontFamilyFallback: [
                            'NotoColorEmoji',
                            'Segoe UI Emoji',
                            'Apple Color Emoji'
                          ],
                        ),
                        shadows: const [
                          Shadow(
                            blurRadius: 5,
                            color: Colors.black54,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "Make your CV your superpower! 📝",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        textStyle: const TextStyle(
                          fontFamilyFallback: [
                            'NotoColorEmoji',
                            'Segoe UI Emoji',
                            'Apple Color Emoji'
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -40,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const CircleAvatar(
                    radius: 45,
                    backgroundImage: AssetImage('assets/images/cvde.jpg'),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 60), // space for avatar

          // ---------- Stepper Section ----------
          Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 4) setState(() => _currentStep++);
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text("Next"),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text("Back"),
                  ),
                ]),
              );
            },
            steps: [
              Step(
                title: const Text("Profile"),
                content: _buildProfileStep(),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text("Education"),
                content: _buildEducationStep(),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: const Text("Experience"),
                content: _buildExperienceStep(),
                isActive: _currentStep >= 2,
              ),
              Step(
                title: const Text("Skills"),
                content: _buildSkillsStep(),
                isActive: _currentStep >= 3,
              ),
              Step(
                title: const Text("Template & Portfolio"),
                content: _buildTemplateStep(),
                isActive: _currentStep >= 4,
              ),
            ],
          ),
        ],
      ),
    ),

    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: _accentColor,
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text("Preview & Export"),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => PdfPreviewPage(buildPdfCallback: _buildPdf),
          ),
        );
      },
    ),

    bottomNavigationBar: AspireBottomBar(
      currentIndex: 4,
      onTap: (index) {
        if (index != 4) {
          Navigator.pop(context);
        }
      },
    ),
  );
}


  Widget _buildProfileStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Full name")),
      const SizedBox(height: 8),
      TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Job title")),
      const SizedBox(height: 8),
      TextField(controller: _summaryCtrl, decoration: const InputDecoration(labelText: "Summary / Objective"), maxLines: 4),
      const SizedBox(height: 8),
      Row(children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.auto_fix_high),
          label: const Text("AI Improve Summary"),
          onPressed: () async {
            final improved = await _aiImprove(_summaryCtrl.text.trim(), 'summary');
            setState(() {
              _summaryCtrl.text = improved;
              _summaryCtrl.selection = TextSelection.fromPosition(TextPosition(offset: improved.length));
            });
          },
        ),
        
      ])
    ]);
  }

  Widget _buildEducationStep() {
    return Column(children: [
      ..._education.asMap().entries.map((e) => ListTile(
            title: Text(e.value),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {
                _eduCtrl.text = e.value;
                showDialog(context: context, builder: (ctx) {
                  return AlertDialog(
                    title: const Text("Edit education"),
                    content: TextField(controller: _eduCtrl),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
                      TextButton(onPressed: () {
                        setState(() {
                          _education[e.key] = _eduCtrl.text.trim();
                        });
                        Navigator.of(ctx).pop();
                      }, child: const Text("Save"))
                    ],
                  );
                });
              }),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _education.removeAt(e.key)))
            ]),
          )),
      Row(children: [
        Expanded(child: TextField(controller: _eduCtrl, decoration: const InputDecoration(hintText: "e.g., B.Sc. Computer Science — University (2019)"))),
        IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF6C95DA)), onPressed: () {
          final t = _eduCtrl.text.trim();
          if (t.isNotEmpty) setState(() {
            _education.add(t);
            _eduCtrl.clear();
          });
        }),
        IconButton(icon: const Icon(Icons.auto_fix_high_outlined), tooltip: "AI improve last education", onPressed: () async {
          if (_education.isEmpty) return;
          final improved = await _aiImprove(_education.last, 'education');
          setState(() => _education[_education.length - 1] = improved);
        })
      ])
    ]);
  }

  Widget _buildExperienceStep() {
    return Column(children: [
      ..._experience.asMap().entries.map((e) => ListTile(
            title: Text(e.value),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {
                _expCtrl.text = e.value;
                showDialog(context: context, builder: (ctx) {
                  return AlertDialog(
                    title: const Text("Edit experience"),
                    content: TextField(controller: _expCtrl),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
                      TextButton(onPressed: () {
                        setState(() {
                          _experience[e.key] = _expCtrl.text.trim();
                        });
                        Navigator.of(ctx).pop();
                      }, child: const Text("Save"))
                    ],
                  );
                });
              }),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _experience.removeAt(e.key)))
            ]),
          )),
      Row(children: [
        Expanded(child: TextField(controller: _expCtrl, decoration: const InputDecoration(hintText: "e.g., Mobile Developer at X — 2020-2023"))),
        IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF6C95DA)), onPressed: () {
          final t = _expCtrl.text.trim();
          if (t.isNotEmpty) setState(() {
            _experience.add(t);
            _expCtrl.clear();
          });
        }),
        IconButton(icon: const Icon(Icons.auto_fix_high_outlined), tooltip: "AI improve last experience", onPressed: () async {
          if (_experience.isEmpty) return;
          final improved = await _aiImprove(_experience.last, 'experience');
          setState(() => _experience[_experience.length - 1] = improved);
        })
      ])
    ]);
  }

  Widget _buildSkillsStep() {
    return Column(children: [
      Wrap(spacing: 6, children: _skills.map((s) => Chip(label: Text(s), onDeleted: () => setState(() => _skills.remove(s)))).toList()),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: _skillCtrl, decoration: const InputDecoration(hintText: "Add skill, e.g., Flutter"))),
        IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF6C95DA)), onPressed: () {
          final t = _skillCtrl.text.trim();
          if (t.isNotEmpty) setState(() {
            _skills.add(t);
            _skillCtrl.clear();
          });
        }),
        IconButton(icon: const Icon(Icons.auto_fix_high_outlined), tooltip: "AI group skills", onPressed: () async {
          final text = _skills.join(", ");
          final improved = await _aiImprove(text, 'skill');
          showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("AI Suggestion"), content: Text(improved), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))]));
        })
      ])
    ]);
  }

  Widget _buildTemplateStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Choose a template (tap thumbnail):", style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      CarouselSlider.builder(
        itemCount: 5,
        itemBuilder: (ctx, idx, realIdx) {
          final sel = idx == _selectedTemplate;
          return GestureDetector(
            onTap: () => setState(() => _selectedTemplate = idx),
            child: Column(children: [
              _templateThumb(idx, sel),
              const SizedBox(height: 6),
              Text("Template ${idx + 1}", style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ]),
          );
        },
        options: CarouselOptions(height: 330, enlargeCenterPage: true, viewportFraction: 0.36),
      ),
      const SizedBox(height: 12),
      Row(children: [
        ElevatedButton.icon(icon: const Icon(Icons.photo_library), label: const Text("Add portfolio images"), onPressed: _pickPortfolioImages),
        const SizedBox(width: 12),
        if (_portfolioImages.isNotEmpty)
          Text("${_portfolioImages.length} image(s) selected", style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      if (_portfolioImages.isNotEmpty)
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => Stack(children: [
              Container(margin: const EdgeInsets.symmetric(horizontal: 6), child: Image.memory(_portfolioImages[i], width: 140, height: 100, fit: BoxFit.cover)),
              Positioned(top: 2, right: 8, child: GestureDetector(onTap: () => setState(() => _portfolioImages.removeAt(i)), child: Container(decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(4), child: const Icon(Icons.close, size: 16, color: Colors.white)))),
            ]),
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemCount: _portfolioImages.length,
          ),
        ),
      const SizedBox(height: 14),
      const Text("Tip: The thumbnail preview reflects the main layout and color used for PDF export."),
    ]);
  }

  // Color picker dialog
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) {
        Color tmp = _accentColor;
        return AlertDialog(
          title: const Text("Pick accent color"),
          content: SingleChildScrollView(child: ColorPicker(pickerColor: _accentColor, onColorChanged: (c) => tmp = c, showLabel: false)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
            TextButton(onPressed: () {
              setState(() => _accentColor = tmp);
              Navigator.of(ctx).pop();
            }, child: const Text("Select"))
          ],
        );
      },
    );
  }
}

// ---------------------------
// PDF Preview page wrapper
// ---------------------------
class PdfPreviewPage extends StatelessWidget {
  final Future<Uint8List> Function(PdfPageFormat) buildPdfCallback;
  const PdfPreviewPage({Key? key, required this.buildPdfCallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview & Export")),
      body: PdfPreview(
        allowPrinting: true,
        allowSharing: true,
        build: (format) => buildPdfCallback(format),
      ),
      
    );
  }
}