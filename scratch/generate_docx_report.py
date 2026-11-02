import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def set_cell_border(cell, **kwargs):
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = parse_xml(f'''
        <w:tcBorders {nsdecls("w")}>
            <w:top w:val="{kwargs.get('val', 'single')}" w:sz="{kwargs.get('sz', '4')}" w:space="0" w:color="{kwargs.get('color', '000000')}"/>
            <w:left w:val="{kwargs.get('left_val', kwargs.get('val', 'single'))}" w:sz="{kwargs.get('sz', '4')}" w:space="0" w:color="{kwargs.get('color', '000000')}"/>
            <w:bottom w:val="{kwargs.get('val', 'single')}" w:sz="{kwargs.get('sz', '4')}" w:space="0" w:color="{kwargs.get('color', '000000')}"/>
            <w:right w:val="{kwargs.get('right_val', kwargs.get('val', 'single'))}" w:sz="{kwargs.get('sz', '4')}" w:space="0" w:color="{kwargs.get('color', '000000')}"/>
        </w:tcBorders>
    ''')
    tcPr.append(tcBorders)

def set_cell_shading(cell, color_hex="F2F2F2"):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{color_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=140, right=140):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'''
        <w:tcMar {nsdecls("w")}>
            <w:top w:w="{top}" w:type="dxa"/>
            <w:bottom w:w="{bottom}" w:type="dxa"/>
            <w:left w:w="{left}" w:type="dxa"/>
            <w:right w:w="{right}" w:type="dxa"/>
        </w:tcMar>
    ''')
    tcPr.append(tcMar)

def create_report_docx(output_path):
    doc = docx.Document()
    
    # Page Setup: A4 Portrait with standard margins
    for section in doc.sections:
        section.page_width = Inches(8.27)
        section.page_height = Inches(11.69)
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        
    # Normal Style -> Times New Roman
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Times New Roman'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = RGBColor(0, 0, 0)
    normal_style.paragraph_format.line_spacing = 1.15
    normal_style.paragraph_format.space_after = Pt(4)

    # Title Header (No RDIB, No 2 Halaman)
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_main = p_title.add_run("LAPORAN UTS — ANALISIS DATA DISKRIT (ADD)\n")
    r_main.font.name = 'Times New Roman'
    r_main.font.size = Pt(16)
    r_main.font.bold = True
    r_main.font.color.rgb = RGBColor(0, 0, 0)
    
    r_sub = p_title.add_run("Analisis Asosiasi Multivariat & Pemodelan Regresi Nominal\n")
    r_sub.font.name = 'Times New Roman'
    r_sub.font.size = Pt(13)
    r_sub.font.bold = True
    r_sub.font.color.rgb = RGBColor(0, 0, 0)
    
    r_meta = p_title.add_run("Studi Kasus: Transaksi Penjualan Frozen Food (April – September 2020 | N = 6.740 Transaksi)\nDepartemen Sistem Informasi — Institut Teknologi Sepuluh Nopember")
    r_meta.font.name = 'Times New Roman'
    r_meta.font.size = Pt(10)
    r_meta.font.italic = True
    r_meta.font.color.rgb = RGBColor(0, 0, 0)
    
    # Horizontal Divider Line (Black)
    p_div = doc.add_paragraph()
    p_div.paragraph_format.space_after = Pt(8)
    p_div_border = parse_xml(f'<w:pBdr {nsdecls("w")}><w:bottom w:val="single" w:sz="12" w:space="1" w:color="000000"/></w:pBdr>')
    p_div._p.get_or_add_pPr().append(p_div_border)

    # 1. Ringkasan Eksekutif & Metodologi
    h1 = doc.add_heading("1. Ringkasan Eksekutif & Metodologi Penelitian", level=1)
    h1.style.font.name = 'Times New Roman'
    h1.style.font.size = Pt(13)
    h1.style.font.bold = True
    h1.style.font.color.rgb = RGBColor(0, 0, 0)
    
    p_desc = doc.add_paragraph(
        "Berdasarkan hasil investigasi komprehensif terhadap 10 rumusan pertanyaan asosiasi pada data penjualan produk frozen food "
        "(N = 6.740 transaksi, 74 merk, 439 item produk, 172 pelanggan), terkonfirmasi 4 nomor pertanyaan yang memiliki hubungan "
        "asosiasi signifikan secara statistik (CONFIRMED):"
    )
    p_desc.runs[0].font.name = 'Times New Roman'
    
    bullets = [
        "Nomor 3: Asosiasi antara Merk (BRAND) dengan Satuan Barang yang Dijual (SATUAN) — Terkonfirmasi Signifikan & Sangat Kuat.",
        "Nomor 6: Asosiasi antara Merk (BRAND) dengan Produk yang Dijual (NAMA_BARANG) — Terkonfirmasi Signifikan & Deterministik Sempurna.",
        "Nomor 8: Asosiasi antara Produk (NAMA_BARANG) dengan Satuan Barang yang Dibeli (SATUAN) — Terkonfirmasi Signifikan & Sangat Kuat.",
        "Nomor 10: Asosiasi antara Pembeli (PELANGGAN) dengan Produk yang Dibeli (NAMA_BARANG) — Terkonfirmasi Signifikan & Khas per Segmen."
    ]
    for b in bullets:
        bp = doc.add_paragraph(style='List Bullet')
        r = bp.add_run(b)
        r.font.name = 'Times New Roman'
        r.font.color.rgb = RGBColor(0, 0, 0)
        bp.paragraph_format.space_after = Pt(2)

    p_metod = doc.add_paragraph()
    r_m_title = p_metod.add_run("Metodologi Analisis Statistik:\n")
    r_m_title.font.name = 'Times New Roman'
    r_m_title.font.bold = True
    r_m_title.font.color.rgb = RGBColor(0, 0, 0)
    r_m_text = p_metod.add_run(
        "1. Uji Independensi Chi-Square (χ²): Menguji hipotesis nol (H₀) bahwa kedua variabel kategorik saling bebas/independen "
        "melawan hipotesis alternatif (H₁) bahwa terdapat asosiasi nyata pada taraf signifikansi α = 0,05.\n"
        "2. Kekuatan Derajat Efek (Cramér's V): Menghitung kekuatan asosiasi nominal dari tabel kontingensi berukuran r × c, dengan nilai "
        "berkisar antara 0 (independen sempurna) hingga 1 (hubungan asosiatif/deterministik mutlak).\n"
        "3. Pemodelan Regresi Nominal (2 Arah Persamaan per Nomor Soal): Mengestimasi fungsi hubungan proporsional/probabilistik antar entitas kategorik: \n"
        "   • Arah 1 (A → B): Menjawab kemungkinan dan bobot kemunculan variabel target B saat entitas A diketahui.\n"
        "   • Arah 2 (B → A): Menjawab kemungkinan dan bobot kemunculan variabel asal A saat entitas B diketahui."
    )
    r_m_text.font.name = 'Times New Roman'

    # Helper function for adding question section
    def add_question_section(sec_num, title, stats_text, tbl_title, tbl_data, fig_path, fig_caption, eq1_title, eq1_case, eq1_form, eq1_prop, eq1_desc, eq2_title, eq2_case, eq2_form, eq2_form2, eq2_desc):
        doc.add_page_break()
        h = doc.add_heading(f"{sec_num}. {title}", level=1)
        h.style.font.name = 'Times New Roman'
        h.style.font.size = Pt(13)
        h.style.font.bold = True
        h.style.font.color.rgb = RGBColor(0, 0, 0)

        p_stat = doc.add_paragraph()
        r = p_stat.add_run("A. Pembuktian Asosiasi & Uji Statistik\n")
        r.font.name = 'Times New Roman'
        r.font.bold = True
        r.font.color.rgb = RGBColor(0, 0, 0)
        r2 = p_stat.add_run(stats_text)
        r2.font.name = 'Times New Roman'

        p_tbl_lbl = doc.add_paragraph()
        r = p_tbl_lbl.add_run(tbl_title)
        r.font.name = 'Times New Roman'
        r.font.bold = True
        r.font.size = Pt(10)

        # Table
        t = doc.add_table(rows=len(tbl_data), cols=len(tbl_data[0]))
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        for i, row in enumerate(tbl_data):
            for j, val in enumerate(row):
                cell = t.cell(i, j)
                cell.text = val
                p = cell.paragraphs[0]
                p.paragraph_format.space_after = Pt(2)
                p.paragraph_format.space_before = Pt(2)
                p.runs[0].font.name = 'Times New Roman'
                p.runs[0].font.size = Pt(9)
                set_cell_margins(cell, top=70, bottom=70, left=90, right=90)
                set_cell_border(cell, color="000000", sz="4")
                if i == 0:
                    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                    p.runs[0].font.bold = True
                    set_cell_shading(cell, "E0E0E0")
                elif j == 0:
                    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
                    p.runs[0].font.bold = True
                else:
                    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT

        # Graph Figure (Oriented clearly across full width)
        if os.path.exists(fig_path):
            p_fig = doc.add_paragraph()
            p_fig.paragraph_format.space_before = Pt(8)
            p_fig.paragraph_format.space_after = Pt(2)
            p_fig.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_fig.add_run().add_picture(fig_path, width=Inches(6.5))
            
            p_cap = doc.add_paragraph()
            p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_cap.paragraph_format.space_after = Pt(6)
            rc = p_cap.add_run(fig_caption)
            rc.font.name = 'Times New Roman'
            rc.font.size = Pt(9)
            rc.font.italic = True

        # Regression Equations
        p_eq_sec = doc.add_paragraph()
        p_eq_sec.paragraph_format.space_before = Pt(4)
        r = p_eq_sec.add_run("B. Dua Persamaan Regresi Nominal\n")
        r.font.name = 'Times New Roman'
        r.font.bold = True
        r.font.color.rgb = RGBColor(0, 0, 0)

        # Box 1
        t_box1 = doc.add_table(rows=1, cols=1)
        t_box1.alignment = WD_TABLE_ALIGNMENT.CENTER
        c1 = t_box1.cell(0, 0)
        set_cell_shading(c1, "F8F8F8")
        set_cell_border(c1, color="000000", sz="8")
        set_cell_margins(c1, top=100, bottom=100, left=150, right=150)
        p1 = c1.paragraphs[0]
        r = p1.add_run(f"{eq1_title}:\n")
        r.font.name = 'Times New Roman'
        r.font.bold = True
        r_c = p1.add_run(f"Pertanyaan Praktis: {eq1_case}\n")
        r_c.font.name = 'Times New Roman'
        r_eq = p1.add_run(f"{eq1_form}\n")
        r_eq.font.name = 'Times New Roman'
        r_eq.font.bold = True
        if eq1_prop:
            r_pr = p1.add_run(f"{eq1_prop}\n")
            r_pr.font.name = 'Times New Roman'
        r_d = p1.add_run(f"Interpretasi: {eq1_desc}")
        r_d.font.name = 'Times New Roman'

        doc.add_paragraph().paragraph_format.space_after = Pt(2)

        # Box 2
        t_box2 = doc.add_table(rows=1, cols=1)
        t_box2.alignment = WD_TABLE_ALIGNMENT.CENTER
        c2 = t_box2.cell(0, 0)
        set_cell_shading(c2, "F8F8F8")
        set_cell_border(c2, color="000000", sz="8")
        set_cell_margins(c2, top=100, bottom=100, left=150, right=150)
        p2 = c2.paragraphs[0]
        r = p2.add_run(f"{eq2_title}:\n")
        r.font.name = 'Times New Roman'
        r.font.bold = True
        r_c = p2.add_run(f"Pertanyaan Praktis: {eq2_case}\n")
        r_c.font.name = 'Times New Roman'
        r_eq = p2.add_run(f"{eq2_form}\n")
        r_eq.font.name = 'Times New Roman'
        r_eq.font.bold = True
        if eq2_form2:
            r_eq2 = p2.add_run(f"{eq2_form2}\n")
            r_eq2.font.name = 'Times New Roman'
            r_eq2.font.bold = True
        r_d = p2.add_run(f"Interpretasi: {eq2_desc}")
        r_d.font.name = 'Times New Roman'

    # Section 2: No 3
    add_question_section(
        sec_num="2",
        title="Nomor 3: Asosiasi Merk Tertentu (BRAND) vs Satuan Barang yang Dijual (SATUAN)",
        stats_text=(
            "• Nilai Uji Chi-Square (χ²): 22.941,68\n"
            "• Derajat Kebebasan (df): 438\n"
            "• Nilai Signifikansi (p-value): 0,0000 (p-value < 0,0001)\n"
            "• Derajat Kekuatan Efek (Cramér's V): 0,7532 (Kategori Asosiasi SANGAT KUAT)\n"
            "• Keputusan Statistik: Tolak H₀ pada taraf signifikansi α = 0,05. Terbukti empiris bahwa satuan kemasan penjualan sangat terikat erat pada merk dagangnya."
        ),
        tbl_title="Tabel 1: Tabel Kontingensi Frekuensi Transaksi Merk Unggulan vs Satuan Kemasan",
        tbl_data=[
            ["Merk (BRAND)", "DUS", "PACK", "PAIL", "BAL", "BKS", "JRG", "Total"],
            ["JOFRANS", "747 (63,7%)", "425 (36,3%)", "0", "0", "0", "0", "1.172"],
            ["OKEY", "591 (76,8%)", "179 (23,2%)", "0", "0", "0", "0", "770"],
            ["MINAKU", "368 (69,0%)", "165 (31,0%)", "0", "0", "0", "0", "533"],
            ["MIAMI", "0", "0", "410 (100%)", "0", "0", "0", "410"],
            ["DEN", "0", "226 (62,8%)", "0", "134 (37,2%)", "0", "0", "360"],
            ["DELMONTE", "6 (24,0%)", "6 (24,0%)", "0", "0", "0", "11 (44,0%)", "25"],
            ["CONE", "0", "0", "0", "0", "55 (100%)", "0", "55"]
        ],
        fig_path=os.path.join("laporan_uts", "figures", "fig_no3_brand_satuan.png"),
        fig_caption="Gambar 1: Visualisasi Tabel Kontingensi dan Pola Sebaran Satuan Kemasan per Merk",
        eq1_title="Jawaban 1 (Menebak Satuan dari Merk Tertentu)",
        eq1_case="Bila Merk JOFRANS dijual, satuan apa yang kemungkinan besar keluar?",
        eq1_form="Merk (JOFRANS) = 3,65 × [DUS] + 2,10 × [PACK] + 0,00 × [PAIL] + ε",
        eq1_prop="Probabilitas Kemunculan: P(Satuan | JOFRANS) = 0,637 [DUS] + 0,363 [PACK] + ε",
        eq1_desc=(
            "Setiap transaksi merk JOFRANS memiliki probabilitas 63,7% keluar dalam satuan DUS (rata-rata volume 3,65 dus per transaksi) "
            "dan 36,3% dalam satuan PACK (rata-rata 2,10 pack per transaksi). Satuan PAIL, BAL, BKS, dan JRG memiliki koefisien 0 karena tidak pernah keluar dalam kemasan tersebut."
        ),
        eq2_title="Jawaban 2 (Menebak Merk dari Satuan Kemasan Tertentu)",
        eq2_case="Bila gudang mengeluarkan satuan PAIL (Ember) atau BAL (Karung), merk apa yang kemungkinan besar dijual?",
        eq2_form="Satuan (PAIL) = 0,804 × [MIAMI] + 0,169 × [INDOESKRIM] + 0,027 × [DIAMOND] + ε",
        eq2_form2="Satuan (BAL) = 0,838 × [DEN] + 0,138 × [PK] + 0,025 × [KEI] + ε",
        eq2_desc=(
            "Apabila bagian gudang mengeluarkan kemasan PAIL, 80,4% dipastikan merupakan es krim merk MIAMI dan 16,9% merk INDOESKRIM. "
            "Jika satuan yang keluar adalah BAL (karung), 83,8% disumbang oleh merk sosis DEN dan 13,8% merk PK."
        )
    )

    # Section 3: No 6
    add_question_section(
        sec_num="3",
        title="Nomor 6: Asosiasi Merk Tertentu (BRAND) vs Produk yang Dijual (NAMA_BARANG)",
        stats_text=(
            "• Nilai Uji Chi-Square (χ²): 492.020,00\n"
            "• Derajat Kebebasan (df): 19.491\n"
            "• Nilai Signifikansi (p-value): 0,0000 (p-value < 0,0001)\n"
            "• Derajat Kekuatan Efek (Cramér's V): 1,0000 (Kategori DETERMINISTIK SEMPURNA)\n"
            "• Keputusan Statistik: Tolak H₀ pada taraf signifikansi α = 0,05. Terbukti terjadi asosiasi deterministik mutlak karena setiap produk dinaungi secara eksklusif oleh satu merk dagang induk."
        ),
        tbl_title="Tabel 2: Tabel Kontingensi Produk Terlaris vs Merk Produsen Induk",
        tbl_data=[
            ["Produk (NAMA_BARANG)", "JOFRANS", "MINAKU", "OKEY", "MIAMI", "DELMONTE", "Total"],
            ["MINAKU OTAK OTAK 500 GR X 20 PACK", "0", "378 (100%)", "0", "0", "0", "378"],
            ["OKEY SOSIS 500 GR X 20 PACK", "0", "0", "288 (100%)", "0", "0", "288"],
            ["JOFRANS NUGGET AYAM HATI 500 GR", "244 (100%)", "0", "0", "0", "0", "244"],
            ["MIAMI ICE CREAM REG. NEAPOLITAN 8 LT", "0", "0", "0", "174 (100%)", "0", "174"],
            ["DELMONTE EXT HOT JRG 5.7 KG", "0", "0", "0", "0", "10 (100%)", "10"]
        ],
        fig_path=os.path.join("laporan_uts", "figures", "fig_no6_brand_produk.png"),
        fig_caption="Gambar 2: Matriks Kontingensi Blok Ortogonal Sempurna Produk vs Merk",
        eq1_title="Jawaban 1 (Menebak Komposisi Produk dari Merk Tertentu)",
        eq1_case="Bila Merk MINAKU dipasarkan/terjual, produk spesifik apa yang kemungkinan besar menyumbang penjualan?",
        eq1_form="Merk (MINAKU) = 5,2 × [Otak-Otak 500g] + 2,1 × [Kentang 7x7] + 1,0 × [Sisik Naga] + 0,8 × [Siomay Udang] + ε",
        eq1_prop="Proporsi Kontribusi: Merk (MINAKU) = 0,709 [Otak-Otak] + 0,036 [Kentang] + 0,030 [Sisik Naga] + ε",
        eq1_desc=(
            "Penjualan merk MINAKU sangat didominasi oleh produk Minaku Otak-Otak 500g yang menyumbang 70,9% frekuensi transaksi "
            "dengan rata-rata volume 5,2 pack per transaksi, disusul varian kentang dan olahan ikan lainnya."
        ),
        eq2_title="Jawaban 2 (Menebak Merk Induk dari Produk / Kategori Tertentu)",
        eq2_case="Bila ada produk kategori NUGGET masuk pesanan/katalog, merk apa yang kemungkinan besar menaunginya?",
        eq2_form="Produk (Kategori Nugget) = 0,951 × [JOFRANS] + 0,018 × [FOODY] + 0,014 × [OKEY] + ε",
        eq2_form2="Persamaan Produk Tunggal: Produk (Minaku Otak-Otak) = 1,00 × [MINAKU] + 0,00 × [JOFRANS] + ε",
        eq2_desc=(
            "Sebanyak 95,1% varian nugget di pasar dinaungi oleh merk JOFRANS. Sedangkan untuk produk spesifik tunggal seperti Minaku Otak-Otak, "
            "probabilitasnya adalah 100% (koefisien 1,00) diproduksi oleh merk MINAKU."
        )
    )

    # Section 4: No 8
    add_question_section(
        sec_num="4",
        title="Nomor 8: Asosiasi Produk Tertentu (NAMA_BARANG) vs Satuan Barang yang Dibeli (SATUAN)",
        stats_text=(
            "• Nilai Uji Chi-Square (χ²): 28.986,89\n"
            "• Derajat Kebebasan (df): 1.602\n"
            "• Nilai Signifikansi (p-value): 0,0000 (p-value < 0,0001)\n"
            "• Derajat Kekuatan Efek (Cramér's V): 0,8466 (Kategori Asosiasi SANGAT KUAT)\n"
            "• Keputusan Statistik: Tolak H₀ pada taraf signifikansi α = 0,05. Terbukti secara empiris bahwa wujud fisik komoditas produk menentukan satuan kemasan secara rigid."
        ),
        tbl_title="Tabel 3: Tabel Kontingensi Produk Terpilih vs Satuan Kemasan Transaksi",
        tbl_data=[
            ["Produk (NAMA_BARANG)", "DUS", "PACK", "PAIL", "BAL", "BKS", "JRG", "Total"],
            ["MINAKU OTAK OTAK 500 GR", "267 (70,6%)", "111 (29,4%)", "0", "0", "0", "0", "378"],
            ["OKEY SOSIS 500 GR X 20 PACK", "239 (83,0%)", "49 (17,0%)", "0", "0", "0", "0", "288"],
            ["MIAMI ICE CREAM NEAPOLITAN 8 LT", "0", "0", "174 (100%)", "0", "0", "0", "174"],
            ["CONE TP 17 ISI 20 (SEDANG)", "0", "0", "0", "0", "35 (100%)", "0", "35"],
            ["DELMONTE EXT HOT JRG 5.7 KG", "0", "0", "0", "0", "0", "10 (100%)", "10"]
        ],
        fig_path=os.path.join("laporan_uts", "figures", "fig_no8_produk_satuan.png"),
        fig_caption="Gambar 3: Distribusi Proporsi Satuan Kemasan per Jenis Komoditas Produk",
        eq1_title="Jawaban 1 (Menebak Satuan Kemasan dari Produk Tertentu)",
        eq1_case="Bila produk Minaku Otak-Otak 500g dibeli, satuan apa yang kemungkinan besar digunakan?",
        eq1_form="Produk (Minaku Otak-Otak) = 0,706 × [DUS] + 0,294 × [PACK] + 0,00 × [PAIL] + ε",
        eq1_prop="Persamaan Produk Es Krim: Produk (Miami Neapolitan 8L) = 1,00 × [PAIL] + 0,00 × [DUS] + ε",
        eq1_desc=(
            "Pembeli produk Minaku Otak-Otak didominasi oleh kulakan partai besar karton DUS (70,6%) untuk stok gerai, "
            "dan 29,4% satuan PACK untuk eceran. Produk es krim ember 8 liter 100% menggunakan satuan PAIL."
        ),
        eq2_title="Jawaban 2 (Menebak Produk di Dalam Satuan Kemasan Khusus)",
        eq2_case="Bila satuan kemasan JRG (Jerigen) atau BKS (Bungkus) dikeluarkan dari gudang, produk apa di dalamnya?",
        eq2_form="Satuan (JRG) = 0,909 × [Delmonte Extra Hot 5,7kg] + 0,091 × [Delmonte Saus Tomat 5,7kg] + ε",
        eq2_form2="Satuan (BKS) = 0,402 × [Cone TP 17 Sedang] + 0,230 × [Cone TP 13 Kecil] + 0,207 × [Kentang 500g] + ε",
        eq2_desc=(
            "Pengeluaran satuan jerigen JRG 100% berisi saus curah Delmonte (90,9% saus cabai ekstra pedas dan 9,1% saus tomat). "
            "Satuan BKS 63,2% berupa wadah es krim kerucut (Cone TP 17 dan TP 13) dan 20,7% kentang curah."
        )
    )

    # Section 5: No 10
    add_question_section(
        sec_num="5",
        title="Nomor 10: Asosiasi Pembeli Tertentu (PELANGGAN) vs Produk yang Dibeli (NAMA_BARANG)",
        stats_text=(
            "• Nilai Uji Chi-Square (χ²): 57.866,01\n"
            "• Derajat Kebebasan (df): 48.060\n"
            "• Nilai Signifikansi (p-value): 3,36 × 10⁻¹⁹⁴ (p-value < 0,0001)\n"
            "• Derajat Kekuatan Efek (Cramér's V): 0,2184 (Kategori Asosiasi NYATA & SIGNIFIKAN)\n"
            "• Keputusan Statistik: Tolak H₀ pada taraf signifikansi α = 0,05. Terbukti empiris adanya pola segmentasi keranjang belanja khas per gerai pelanggan."
        ),
        tbl_title="Tabel 4: Tabel Kontingensi Frekuensi Transaksi Pelanggan Mitra vs Komoditas Produk Terpilih",
        tbl_data=[
            ["Pelanggan", "Otak-Otak", "Baso Sapi", "Nugget Hati", "Kentang", "Fish Tofu", "Total Trx"],
            ["ADEK FROZEN", "12 (4,2%)", "11 (3,9%)", "12 (4,2%)", "12 (4,2%)", "8 (2,8%)", "285"],
            ["AMANAH FROZEN", "19 (5,4%)", "2 (0,6%)", "9 (2,5%)", "0", "11 (3,1%)", "354"],
            ["TOKO CITA RASA BARU", "42 (8,0%)", "0", "15 (2,8%)", "1 (0,2%)", "14 (2,7%)", "528"],
            ["ACHEN / VINCENT", "5 (3,8%)", "4 (3,1%)", "0", "2 (1,5%)", "3 (2,3%)", "130"],
            ["ANTON", "3 (4,3%)", "6 (8,6%)", "0", "0", "1 (1,4%)", "70"]
        ],
        fig_path=os.path.join("laporan_uts", "figures", "fig_no10_pelanggan_produk.png"),
        fig_caption="Gambar 4: Profiling Keranjang Belanja dan Distribusi Kuantitas Belanja Pelanggan Mitra",
        eq1_title="Jawaban 1 (Menebak Produk yang Dibeli jika Pembeli Tertentu Datang)",
        eq1_case="Bila Pembeli ADEK FROZEN datang, maka produk apa yang kemungkinan besar dibeli?",
        eq1_form="Pembeli (Adek Frozen) = 2,4 × [Jofrans Nugget] + 1,8 × [Minaku Otak-Otak] + 1,2 × [Minaku Kentang] + 0,9 × [Jofrans Baso Sapi] + ε",
        eq1_prop="Persamaan Rata-rata Kuantitas (QTY) Riil: Pembeli (Adek Frozen) = 16,7 [Otak-Otak] + 12,9 [Nugget Hati] + 7,3 [Kentang] + 5,6 [Baso Sapi] + ε",
        eq1_desc=(
            "Ketika gerai Adek Frozen berbelanja, komoditas nugget dan otak-otak menjadi prioritas utama dengan koefisien bobot tertinggi "
            "(2,4 dan 1,8), dengan rata-rata volume sekali belanja mencapai 12–17 kemasan."
        ),
        eq2_title="Jawaban 2 (Menebak Pembeli jika Stok Produk Tertentu Tersedia)",
        eq2_case="Bila ada produk datang/baru tiba di gudang (Jofrans Baso Sapi atau Minaku Otak-Otak), kemungkinan besar dibeli oleh siapa?",
        eq2_form="Produk (Jofrans Baso Sapi) = 3,2 × [Adek Frozen] + 2,1 × [Anton] + 1,8 × [Rumah Sosis] + 1,2 × [Achen / Vincent] + ε",
        eq2_form2="Produk (Minaku Otak-Otak) = 4,5 × [Toko Cita Rasa Baru] + 3,2 × [Amanah Frozen] + 2,4 × [Adek Frozen] + ε",
        eq2_desc=(
            "Apabila pasokan Jofrans Baso Sapi tiba di gudang, daya serap terbesar dimiliki oleh Adek Frozen (koefisien 3,2) dan Anton (koefisien 2,1). "
            "Sebaliknya, jika pasokan Minaku Otak-Otak yang tiba, penyerap terbesar adalah Toko Cita Rasa Baru (koefisien 4,5) dan Amanah Frozen (koefisien 3,2)."
        )
    )

    # Section 6: Rangkuman Matriks 8 Persamaan
    doc.add_page_break()
    h6 = doc.add_heading("6. Rangkuman Matriks 8 Persamaan Regresi Nominal", level=1)
    h6.style.font.name = 'Times New Roman'
    h6.style.font.size = Pt(13)
    h6.style.font.bold = True
    h6.style.font.color.rgb = RGBColor(0, 0, 0)

    p_m_desc = doc.add_paragraph(
        "Tabel berikut merangkum seluruh 8 persamaan regresi nominal terkonfirmasi (masing-masing 2 persamaan matematis per nomor soal):"
    )
    p_m_desc.runs[0].font.name = 'Times New Roman'

    matrix_data = [
        ["No", "Pasangan Asosiasi", "Persamaan Regresi Arah 1 (A → B)", "Persamaan Regresi Arah 2 (B → A)", "Status"],
        [
            "3",
            "Merk ↔ Satuan Kemasan",
            "Merk (JOFRANS) = 3,65 [DUS] + 2,10 [PACK] + ε\nP(Satuan | JOFRANS) = 0,637 [DUS] + 0,363 [PACK]",
            "Satuan (PAIL) = 0,804 [MIAMI] + 0,169 [INDOESKRIM] + ε\nSatuan (BAL) = 0,838 [DEN] + 0,138 [PK] + ε",
            "CONFIRMED"
        ],
        [
            "6",
            "Merk ↔ Produk",
            "Merk (MINAKU) = 5,2 [Otak-Otak] + 2,1 [Kentang] + 1,0 [Sisik Naga] + ε\nP(Produk | MINAKU) = 0,709 [Otak-Otak] + 0,036 [Kentang]",
            "Produk (Kategori Nugget) = 0,951 [JOFRANS] + 0,018 [FOODY] + ε\nProduk (Minaku Otak-Otak) = 1,00 [MINAKU] + ε",
            "CONFIRMED"
        ],
        [
            "8",
            "Produk ↔ Satuan Kemasan",
            "Produk (Otak-Otak) = 0,706 [DUS] + 0,294 [PACK] + ε\nProduk (Miami 8L) = 1,00 [PAIL] + ε",
            "Satuan (JRG) = 0,909 [Delmonte Pedas] + 0,091 [Tomat] + ε\nSatuan (BKS) = 0,402 [Cone TP17] + 0,230 [Cone TP13] + ε",
            "CONFIRMED"
        ],
        [
            "10",
            "Pembeli ↔ Produk",
            "Pembeli (Adek Frozen) = 2,4 [Nugget] + 1,8 [Otak-Otak] + 1,2 [Kentang] + ε\nQTY (Adek Frozen) = 16,7 [Otak-Otak] + 12,9 [Nugget Hati]",
            "Produk (Baso Sapi) = 3,2 [Adek Frozen] + 2,1 [Anton] + 1,8 [Rumah Sosis] + ε\nProduk (Otak-Otak) = 4,5 [Cita Rasa Baru] + 3,2 [Amanah]",
            "CONFIRMED"
        ]
    ]

    tm = doc.add_table(rows=len(matrix_data), cols=len(matrix_data[0]))
    tm.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, row in enumerate(matrix_data):
        for j, val in enumerate(row):
            cell = tm.cell(i, j)
            cell.text = val
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.space_before = Pt(2)
            p.runs[0].font.name = 'Times New Roman'
            p.runs[0].font.size = Pt(9)
            set_cell_margins(cell, top=80, bottom=80, left=80, right=80)
            set_cell_border(cell, color="000000", sz="4")
            if i == 0:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p.runs[0].font.bold = True
                set_cell_shading(cell, "E0E0E0")
            elif j == 0 or j == 4:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p.runs[0].font.bold = True
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT

    # Section 7: Kesimpulan & Rekomendasi Manajerial
    h7 = doc.add_heading("7. Kesimpulan & Rekomendasi Manajerial Bisnis", level=1)
    h7.style.font.name = 'Times New Roman'
    h7.style.font.size = Pt(13)
    h7.style.font.bold = True
    h7.style.font.color.rgb = RGBColor(0, 0, 0)
    
    p_rec = doc.add_paragraph(
        "1. Penataan Tata Letak Gudang & Efisiensi Picking:\n"
        "   Berdasarkan asosiasi kuat antara kemasan dan merk (No 3 & No 8), zonasi cold storage harus dipisahkan berdasarkan "
        "karakteristik fisik kemasan: area pallet untuk karton DUS (sosis & nugget), rak pendingin khusus ember PAIL (es krim 8 liter), "
        "serta ruang kering khusus jerigen JRG saus dan bungkus BKS cone es krim.\n\n"
        "2. Kebijakan Minimum Order Quantity (MOQ) & Bundling:\n"
        "   Pada produk fast-moving seperti Minaku Otak-Otak dan Okey Sosis (No 8), 70%–83% transaksi keluar dalam satuan karton DUS. "
        "Distributor disarankan menerapkan diskon bertingkat untuk pembelian satuan DUS guna mempercepat perputaran inventori.\n\n"
        "3. Manajemen Hubungan Pelanggan (CRM) & Alokasi Pasokan Cerdas:\n"
        "   Melalui model regresi Nomor 10, saat pasokan Jofrans Baso Sapi tiba, tim sales dapat langsung melakukan pre-order tertarget "
        "kepada Adek Frozen dan Anton. Sedangkan jika pasokan Minaku Otak-Otak datang, alokasi stok prioritas langsung disalurkan kepada Toko Cita Rasa Baru."
    )
    p_rec.runs[0].font.name = 'Times New Roman'

    doc.save(output_path)
    print(f"File DOCX berhasil disimpan di: {output_path}")

if __name__ == '__main__':
    out1 = os.path.join("laporan_uts", "Laporan_Tugas_Regresi_Nominal_ADD.docx")
    create_report_docx(out1)
    out2 = "Laporan_Tugas_Regresi_Nominal_ADD.docx"
    create_report_docx(out2)
