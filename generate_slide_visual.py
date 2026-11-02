import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

plt.switch_backend('Agg')

DATA_PATH = os.path.join('bersih', 'penjualan_bersih.csv')
OUTPUT_DIR = 'slide_assets'
os.makedirs(OUTPUT_DIR, exist_ok=True)

df = pd.read_csv(DATA_PATH)

selected_brands = [
    'JOFRANS', 'OKEY', 'MINAKU', 'BELFOODS', 'LUTOSA', 'CHAMP',
    'MITRAKU', 'ILM', 'DEN', 'PK',
    'MIAMI', 'INDOESKRIM', 'DELMONTE', 'CONE'
]
satuan_order = ['DUS', 'PACK', 'PAIL', 'BAL', 'BKS', 'JRG', 'PCS']

df_sub = df.copy()
df_sub['BRAND_DISPLAY'] = df_sub['BRAND'].apply(lambda x: x if x in selected_brands else 'LAINNYA (60 Merk)')

# Crosstab Frekuensi Mentah
ct_raw = pd.crosstab(df_sub['BRAND_DISPLAY'], df_sub['SATUAN'])
ct_matrix = ct_raw.reindex(index=selected_brands + ['LAINNYA (60 Merk)'], columns=satuan_order).fillna(0).astype(int)

row_totals = ct_matrix.sum(axis=1)
col_totals = ct_matrix.sum(axis=0)
grand_total = ct_matrix.values.sum()
row_pct = ct_matrix.div(row_totals, axis=0) * 100

n_rows = len(ct_matrix)
n_cols = len(satuan_order)

# ==============================================================================
# VISUALISASI 1: EXECUTIVE DARK THEME (16:9 SLIDE PRESENTATION READY)
# ==============================================================================
fig = plt.figure(figsize=(16, 9), dpi=300, facecolor='#0B132B')
gs = fig.add_gridspec(1, 2, width_ratios=[1.65, 1.1], wspace=0.12, left=0.045, right=0.965, top=0.88, bottom=0.06)

ax_mat = fig.add_subplot(gs[0, 0])
ax_side = fig.add_subplot(gs[0, 1])

# Header
fig.text(0.045, 0.948, "ANALISIS ASOSIASI KATEGORIKAL  |  BRAND VS SATUAN JUAL", 
         fontsize=11, fontweight='bold', color='#38BDF8', family='sans-serif')
fig.text(0.045, 0.908, "Tabel Kontingensi: Frekuensi Transaksi Riil & Proporsi Kemasan", 
         fontsize=19, fontweight='bold', color='#F8FAFC', family='sans-serif')
fig.text(0.045, 0.880, "Angka tebal: Volume Riil Transaksi (Oij)  |  Angka kurung: Persentase Baris per Merk  |  Total: 6.740 Transaksi", 
         fontsize=10.5, color='#94A3B8', family='sans-serif')

# Matrix Plot
ax_mat.set_facecolor('#0B132B')
cmap = plt.cm.Blues

for r_idx, brand in enumerate(ct_matrix.index):
    y_pos = n_rows - 1 - r_idx
    r_total = row_totals[brand]
    
    brand_color = '#F1F5F9' if brand != 'LAINNYA (60 Merk)' else '#94A3B8'
    ax_mat.text(-0.55, y_pos, brand, ha='right', va='center', fontsize=9.8, 
                fontweight='bold' if brand != 'LAINNYA (60 Merk)' else 'normal',
                color=brand_color, family='sans-serif')
    
    for c_idx, sat in enumerate(satuan_order):
        cnt = ct_matrix.loc[brand, sat]
        pct = row_pct.loc[brand, sat]
        
        if cnt == 0:
            box_color = '#1E293B'
            border_color = '#334155'
        else:
            norm_val = 0.25 + (pct / 100.0) * 0.70
            box_color = cmap(norm_val)
            border_color = '#60A5FA' if pct >= 50 else '#3B82F6'
        
        rect = FancyBboxPatch((c_idx - 0.44, y_pos - 0.42), 0.88, 0.84,
                              boxstyle="round,pad=0.03,rounding_size=0.10",
                              facecolor=box_color, edgecolor=border_color, linewidth=1.0, zorder=2)
        ax_mat.add_patch(rect)
        
        if cnt == 0:
            ax_mat.text(c_idx, y_pos, "—", ha='center', va='center', 
                        fontsize=11, color='#64748B', zorder=3)
        else:
            text_color = '#FFFFFF' if pct >= 35 else '#0F172A'
            sub_color = '#E2E8F0' if pct >= 35 else '#334155'
            
            ax_mat.text(c_idx, y_pos + 0.12, f"{cnt:,}", ha='center', va='center',
                        fontsize=10.2, fontweight='bold', color=text_color, zorder=3)
            ax_mat.text(c_idx, y_pos - 0.15, f"{pct:.1f}%", ha='center', va='center',
                        fontsize=8.2, fontweight='medium', color=sub_color, zorder=3)
    
    # Margin Kanan (Total Baris)
    rect_tot = FancyBboxPatch((n_cols - 0.42, y_pos - 0.42), 0.95, 0.84,
                              boxstyle="round,pad=0.03,rounding_size=0.10",
                              facecolor='#1E293B', edgecolor='#475569', linewidth=1.2, zorder=2)
    ax_mat.add_patch(rect_tot)
    ax_mat.text(n_cols + 0.05, y_pos + 0.10, f"{r_total:,}", ha='center', va='center',
                fontsize=10.2, fontweight='bold', color='#38BDF8', zorder=3)
    pct_of_grand = (r_total / grand_total) * 100
    ax_mat.text(n_cols + 0.05, y_pos - 0.15, f"({pct_of_grand:.1f}%)", ha='center', va='center',
                fontsize=7.8, color='#94A3B8', zorder=3)

# Header Kolom (Satuan)
for c_idx, sat in enumerate(satuan_order):
    ax_mat.text(c_idx, n_rows - 0.1, sat, ha='center', va='bottom',
                fontsize=11, fontweight='bold', color='#38BDF8', family='sans-serif')

ax_mat.text(n_cols + 0.05, n_rows - 0.1, "TOTAL", ha='center', va='bottom',
            fontsize=11, fontweight='bold', color='#F8FAFC', family='sans-serif')

# Baris Margin Bawah (Total Kolom)
y_bottom = -1.1
ax_mat.text(-0.55, y_bottom, "TOTAL PASAR", ha='right', va='center',
            fontsize=9.8, fontweight='bold', color='#38BDF8', family='sans-serif')

for c_idx, sat in enumerate(satuan_order):
    c_tot = col_totals[sat]
    rect_b = FancyBboxPatch((c_idx - 0.44, y_bottom - 0.42), 0.88, 0.84,
                            boxstyle="round,pad=0.03,rounding_size=0.10",
                            facecolor='#1E293B', edgecolor='#38BDF8', linewidth=1.2, zorder=2)
    ax_mat.add_patch(rect_b)
    ax_mat.text(c_idx, y_bottom + 0.10, f"{c_tot:,}", ha='center', va='center',
                fontsize=10.2, fontweight='bold', color='#F8FAFC', zorder=3)
    c_pct = (c_tot / grand_total) * 100
    ax_mat.text(c_idx, y_bottom - 0.15, f"({c_pct:.1f}%)", ha='center', va='center',
                fontsize=7.8, color='#94A3B8', zorder=3)

# Grand Total
rect_grand = FancyBboxPatch((n_cols - 0.42, y_bottom - 0.42), 0.95, 0.84,
                            boxstyle="round,pad=0.03,rounding_size=0.10",
                            facecolor='#0284C7', edgecolor='#38BDF8', linewidth=1.5, zorder=2)
ax_mat.add_patch(rect_grand)
ax_mat.text(n_cols + 0.05, y_bottom + 0.10, f"{grand_total:,}", ha='center', va='center',
            fontsize=10.5, fontweight='heavy', color='#FFFFFF', zorder=3)
ax_mat.text(n_cols + 0.05, y_bottom - 0.15, "100%", ha='center', va='center',
            fontsize=8.2, fontweight='bold', color='#E0F2FE', zorder=3)

ax_mat.set_xlim(-2.1, n_cols + 0.7)
ax_mat.set_ylim(-1.8, n_rows + 0.6)
ax_mat.axis('off')

# Side Panel
ax_side.set_facecolor('#0B132B')
ax_side.set_xlim(0, 1)
ax_side.set_ylim(0, 1)
ax_side.axis('off')

# Box Uji Statistik
stat_box = FancyBboxPatch((0.02, 0.73), 0.96, 0.25,
                          boxstyle="round,pad=0.01,rounding_size=0.04",
                          facecolor='#1E293B', edgecolor='#38BDF8', linewidth=1.5)
ax_side.add_patch(stat_box)

ax_side.text(0.06, 0.93, "HASIL UJI STATISTIK RESMI", fontsize=11, fontweight='bold', color='#38BDF8')
ax_side.text(0.06, 0.86, "Chi-Square (χ²)", fontsize=9.5, color='#94A3B8')
ax_side.text(0.92, 0.86, "22.941,68", fontsize=10, fontweight='bold', color='#F8FAFC', ha='right')
ax_side.text(0.06, 0.80, "p-value", fontsize=9.5, color='#94A3B8')
ax_side.text(0.92, 0.80, "< 0.0001 (Sig.)", fontsize=10, fontweight='bold', color='#4ADE80', ha='right')
ax_side.text(0.06, 0.74, "Cramér's V (Kekuatan)", fontsize=9.5, color='#94A3B8')
ax_side.text(0.92, 0.74, "0.7532 (Sangat Kuat)", fontsize=10, fontweight='bold', color='#FACC15', ha='right')

# Box Temuan Kunci
takeaway_box = FancyBboxPatch((0.02, 0.02), 0.96, 0.68,
                              boxstyle="round,pad=0.01,rounding_size=0.04",
                              facecolor='#1E293B', edgecolor='#334155', linewidth=1.2)
ax_side.add_patch(takeaway_box)

ax_side.text(0.06, 0.645, "TEMUAN & POLA BISNIS UTAMA", fontsize=11, fontweight='bold', color='#F8FAFC')

card_items = [
    ("1. Polarisasi Es Krim & Pelengkap",
     "• MIAMI & INDOESKRIM murni 100% PAIL\n  (496 transaksi ember es krim curah).\n• CONE 100% menggunakan BKS (55 tx).",
     '#38BDF8'),
    ("2. Monopoli Kemasan Jerigen (JRG)",
     "• DELMONTE menguasai 100% total transaksi\n  JRG di pasar (11 transaksi saus jerigen).",
     '#FB7185'),
    ("3. Dualitas Grosir & Retail Frozen",
     "• JOFRANS, OKEY, MINAKU, BELFOODS\n  terbagi ke DUS (63-77%) dan PACK (23-37%).",
     '#60A5FA'),
    ("4. Spesialisasi Kemasan Karung (BAL)",
     "• DEN & PK menyerap kemasan BAL (156 tx)\n  dan sama sekali tanpa transaksi DUS.",
     '#A78BFA')
]

y_pos_card = 0.585
for title, text_body, col in card_items:
    ax_side.text(0.06, y_pos_card, title, fontsize=9.5, fontweight='bold', color=col)
    y_pos_card -= 0.032
    ax_side.text(0.06, y_pos_card, text_body, fontsize=8.6, color='#CBD5E1', va='top', linespacing=1.25)
    y_pos_card -= 0.088

slide_path_1 = os.path.join(OUTPUT_DIR, 'slide_kontingensi_matrix_executive.png')
plt.savefig(slide_path_1, dpi=300, facecolor='#0B132B')
plt.close()

# ==============================================================================
# VISUALISASI 2: LIGHT CONSULTING PRESENTATION (16:9 CLEAN)
# ==============================================================================
fig = plt.figure(figsize=(16, 9), dpi=300, facecolor='#F8FAFC')
gs_l = fig.add_gridspec(1, 2, width_ratios=[1.65, 1.1], wspace=0.12, left=0.045, right=0.965, top=0.88, bottom=0.06)

ax_l_mat = fig.add_subplot(gs_l[0, 0])
ax_l_side = fig.add_subplot(gs_l[0, 1])

# Header
fig.text(0.045, 0.948, "ANALISIS KETERGANTUNGAN SATUAN TERHADAP MERK PRODUK", 
         fontsize=11, fontweight='bold', color='#0284C7', family='sans-serif')
fig.text(0.045, 0.908, "Tabel Kontingensi: Frekuensi Transaksi Riil & Proporsi Kemasan", 
         fontsize=19, fontweight='bold', color='#0F172A', family='sans-serif')
fig.text(0.045, 0.880, "Angka tebal: Jumlah Transaksi Riil (Oij)  |  Angka kurung: Persentase Baris per Merk  |  Grand Total: 6.740 Transaksi", 
         fontsize=10.5, color='#64748B', family='sans-serif')

ax_l_mat.set_facecolor('#F8FAFC')
cmap_light = plt.cm.Blues

for r_idx, brand in enumerate(ct_matrix.index):
    y_pos = n_rows - 1 - r_idx
    r_total = row_totals[brand]
    
    brand_fontweight = 'bold' if brand != 'LAINNYA (60 Merk)' else 'normal'
    ax_l_mat.text(-0.55, y_pos, brand, ha='right', va='center', fontsize=9.8, 
                  fontweight=brand_fontweight, color='#1E293B')
    
    for c_idx, sat in enumerate(satuan_order):
        cnt = ct_matrix.loc[brand, sat]
        pct = row_pct.loc[brand, sat]
        
        if cnt == 0:
            box_fc = '#FFFFFF'
            box_ec = '#E2E8F0'
        else:
            norm_val = 0.12 + (pct / 100.0) * 0.78
            box_fc = cmap_light(norm_val)
            box_ec = '#93C5FD' if pct < 50 else '#1D4ED8'
            
        rect = FancyBboxPatch((c_idx - 0.44, y_pos - 0.42), 0.88, 0.84,
                              boxstyle="round,pad=0.03,rounding_size=0.10",
                              facecolor=box_fc, edgecolor=box_ec, linewidth=1.0)
        ax_l_mat.add_patch(rect)
        
        if cnt == 0:
            ax_l_mat.text(c_idx, y_pos, "—", ha='center', va='center', fontsize=11, color='#94A3B8')
        else:
            txt_c = '#FFFFFF' if pct >= 45 else '#0F172A'
            sub_c = '#EFF6FF' if pct >= 45 else '#475569'
            ax_l_mat.text(c_idx, y_pos + 0.12, f"{cnt:,}", ha='center', va='center',
                          fontsize=10.2, fontweight='bold', color=txt_c)
            ax_l_mat.text(c_idx, y_pos - 0.15, f"{pct:.1f}%", ha='center', va='center',
                          fontsize=8.2, color=sub_c)

    # Total Baris
    rect_r = FancyBboxPatch((n_cols - 0.42, y_pos - 0.42), 0.95, 0.84,
                            boxstyle="round,pad=0.03,rounding_size=0.10",
                            facecolor='#FFFFFF', edgecolor='#CBD5E1', linewidth=1.2)
    ax_l_mat.add_patch(rect_r)
    ax_l_mat.text(n_cols + 0.05, y_pos + 0.10, f"{r_total:,}", ha='center', va='center',
                  fontsize=10.2, fontweight='bold', color='#0369A1')
    ax_l_mat.text(n_cols + 0.05, y_pos - 0.15, f"({r_total/grand_total*100:.1f}%)", ha='center', va='center',
                  fontsize=7.8, color='#64748B')

# Header Kolom
for c_idx, sat in enumerate(satuan_order):
    ax_l_mat.text(c_idx, n_rows - 0.1, sat, ha='center', va='bottom',
                  fontsize=11, fontweight='bold', color='#0369A1')

ax_l_mat.text(n_cols + 0.05, n_rows - 0.1, "TOTAL", ha='center', va='bottom',
              fontsize=11, fontweight='bold', color='#0F172A')

# Total Kolom
y_bottom = -1.1
ax_l_mat.text(-0.55, y_bottom, "TOTAL PASAR", ha='right', va='center',
              fontsize=9.8, fontweight='bold', color='#0369A1')

for c_idx, sat in enumerate(satuan_order):
    c_tot = col_totals[sat]
    rect_cb = FancyBboxPatch((c_idx - 0.44, y_bottom - 0.42), 0.88, 0.84,
                             boxstyle="round,pad=0.03,rounding_size=0.10",
                             facecolor='#FFFFFF', edgecolor='#94A3B8', linewidth=1.2)
    ax_l_mat.add_patch(rect_cb)
    ax_l_mat.text(c_idx, y_bottom + 0.10, f"{c_tot:,}", ha='center', va='center',
                  fontsize=10.2, fontweight='bold', color='#0F172A')
    ax_l_mat.text(c_idx, y_bottom - 0.15, f"({c_tot/grand_total*100:.1f}%)", ha='center', va='center',
                  fontsize=7.8, color='#64748B')

# Grand Total
rect_gt = FancyBboxPatch((n_cols - 0.42, y_bottom - 0.42), 0.95, 0.84,
                         boxstyle="round,pad=0.03,rounding_size=0.10",
                         facecolor='#0284C7', edgecolor='#0369A1', linewidth=1.5)
ax_l_mat.add_patch(rect_gt)
ax_l_mat.text(n_cols + 0.05, y_bottom + 0.10, f"{grand_total:,}", ha='center', va='center',
              fontsize=10.5, fontweight='heavy', color='#FFFFFF')
ax_l_mat.text(n_cols + 0.05, y_bottom - 0.15, "100%", ha='center', va='center',
              fontsize=8.2, fontweight='bold', color='#E0F2FE')

ax_l_mat.set_xlim(-2.1, n_cols + 0.7)
ax_l_mat.set_ylim(-1.8, n_rows + 0.6)
ax_l_mat.axis('off')

# Side Panel Light
ax_l_side.set_facecolor('#F8FAFC')
ax_l_side.set_xlim(0, 1)
ax_l_side.set_ylim(0, 1)
ax_l_side.axis('off')

stat_box_l = FancyBboxPatch((0.02, 0.73), 0.96, 0.25,
                            boxstyle="round,pad=0.01,rounding_size=0.04",
                            facecolor='#FFFFFF', edgecolor='#0284C7', linewidth=1.5)
ax_l_side.add_patch(stat_box_l)

ax_l_side.text(0.06, 0.93, "HASIL UJI STATISTIK RESMI", fontsize=11, fontweight='bold', color='#0284C7')
ax_l_side.text(0.06, 0.86, "Chi-Square (χ²)", fontsize=9.5, color='#64748B')
ax_l_side.text(0.92, 0.86, "22.941,68", fontsize=10, fontweight='bold', color='#0F172A', ha='right')
ax_l_side.text(0.06, 0.80, "p-value", fontsize=9.5, color='#64748B')
ax_l_side.text(0.92, 0.80, "< 0.0001 (Signifikan)", fontsize=10, fontweight='bold', color='#16A34A', ha='right')
ax_l_side.text(0.06, 0.74, "Cramér's V (Kekuatan)", fontsize=9.5, color='#64748B')
ax_l_side.text(0.92, 0.74, "0.7532 (Sangat Kuat)", fontsize=10, fontweight='bold', color='#D97706', ha='right')

takeaway_box_l = FancyBboxPatch((0.02, 0.02), 0.96, 0.68,
                                boxstyle="round,pad=0.01,rounding_size=0.04",
                                facecolor='#FFFFFF', edgecolor='#CBD5E1', linewidth=1.2)
ax_l_side.add_patch(takeaway_box_l)

ax_l_side.text(0.06, 0.645, "TEMUAN & POLA BISNIS UTAMA", fontsize=11, fontweight='bold', color='#0F172A')

card_items_light = [
    ("1. Polarisasi Es Krim & Pelengkap",
     "• MIAMI & INDOESKRIM murni 100% PAIL\n  (496 transaksi ember es krim curah).\n• CONE 100% menggunakan BKS (55 tx).",
     '#0284C7'),
    ("2. Monopoli Kemasan Jerigen (JRG)",
     "• DELMONTE menguasai 100% total transaksi\n  JRG di pasar (11 transaksi saus jerigen).",
     '#E11D48'),
    ("3. Dualitas Grosir & Retail Frozen",
     "• JOFRANS, OKEY, MINAKU, BELFOODS\n  terbagi ke DUS (63-77%) dan PACK (23-37%).",
     '#2563EB'),
    ("4. Spesialisasi Kemasan Karung (BAL)",
     "• DEN & PK menyerap kemasan BAL (156 tx)\n  dan sama sekali tanpa transaksi DUS.",
     '#7C3AED')
]

y_pos_card_l = 0.585
for title, text_body, col in card_items_light:
    ax_l_side.text(0.06, y_pos_card_l, title, fontsize=9.5, fontweight='bold', color=col)
    y_pos_card_l -= 0.032
    ax_l_side.text(0.06, y_pos_card_l, text_body, fontsize=8.6, color='#475569', va='top', linespacing=1.25)
    y_pos_card_l -= 0.088

slide_path_2 = os.path.join(OUTPUT_DIR, 'slide_kontingensi_matrix_light.png')
plt.savefig(slide_path_2, dpi=300, facecolor='#F8FAFC')
plt.close()

# ==============================================================================
# VISUALISASI 3: HORIZONTAL STACKED BAR CHART (DIPERBAIKI HEADER & LEGENDA)
# ==============================================================================
fig, ax = plt.subplots(figsize=(16, 9), dpi=300, facecolor='#FFFFFF')
ax.set_facecolor('#FFFFFF')

brands_bar = selected_brands + ['LAINNYA (60 Merk)']
ct_bar = ct_matrix.loc[brands_bar]

satuan_colors = {
    'DUS': '#0284C7',
    'PACK': '#3B82F6',
    'PAIL': '#0D9488',
    'BAL': '#8B5CF6',
    'BKS': '#F59E0B',
    'JRG': '#EF4444',
    'PCS': '#64748B'
}

y_indices = np.arange(len(brands_bar))[::-1]
left_accum = np.zeros(len(brands_bar))

for sat in satuan_order:
    values = ct_bar[sat].values
    bars = ax.barh(y_indices, values, left=left_accum, color=satuan_colors[sat], 
                   label=sat, edgecolor='white', height=0.68, linewidth=0.8)
    
    for idx, (val, left_v) in enumerate(zip(values, left_accum)):
        if val >= 45:
            pct_val = row_pct.loc[brands_bar[idx], sat]
            label_text = f"{val}\n({pct_val:.0f}%)" if val >= 150 else f"{val}"
            ax.text(left_v + val / 2, y_indices[idx], label_text,
                    ha='center', va='center', color='white', fontsize=7.5, fontweight='bold')
    
    left_accum += values

for idx, total_v in enumerate(left_accum):
    ax.text(total_v + 15, y_indices[idx], f"{int(total_v):,} tx", 
            ha='left', va='center', fontsize=9.5, fontweight='bold', color='#1E293B')

ax.set_yticks(y_indices)
ax.set_yticklabels(brands_bar, fontsize=10.5, fontweight='semibold', color='#1E293B')
ax.set_xlabel('Volume Jumlah Transaksi Riil (Unit Transaksi)', fontsize=11, fontweight='bold', color='#334155', labelpad=10)
ax.set_xlim(0, max(left_accum) * 1.12)

# Grid & Spines
ax.grid(axis='x', linestyle='--', alpha=0.4, color='#CBD5E1')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_color('#94A3B8')
ax.spines['bottom'].set_color('#94A3B8')

# Header terpisah tanpa tumpang tindih
fig.text(0.06, 0.948, "KOMPOSISI VOLUME PENJUALAN PER MERK", fontsize=11, fontweight='bold', color='#0284C7')
fig.text(0.06, 0.912, "Grafik Frekuensi Transaksi Satuan per Merk (Horizontal Stacked Bar)", fontsize=18, fontweight='bold', color='#0F172A')
fig.text(0.06, 0.880, "Panjang bar = total transaksi merk. Segmen warna = pembagian satuan kemasan.", fontsize=10.5, color='#64748B')

# Legenda di posisi aman sebelah kanan atas
ax.legend(loc='upper right', bbox_to_anchor=(0.99, 1.05), ncol=7, frameon=True, 
          facecolor='#F8FAFC', edgecolor='#CBD5E1', fontsize=9.5, title="Satuan Kemasan:", title_fontsize=10)

plt.subplots_adjust(top=0.84, bottom=0.08, left=0.135, right=0.96)

slide_path_3 = os.path.join(OUTPUT_DIR, 'slide_stacked_bar_frekuensi.png')
plt.savefig(slide_path_3, dpi=300, facecolor='#FFFFFF')
plt.close()
print("Semua slide diperbarui dengan sempurna!")
