import warnings
warnings.filterwarnings('ignore')
import pandas as pd
import numpy as np

# Cell 1
print("Testing Cell 1...")
df_clean = pd.read_csv('bersih/penjualan_bersih.csv', parse_dates=['TGL'])
df_lrfm  = pd.read_csv('bersih/lrfm_pelanggan.csv')
df_rules = pd.read_csv('bersih/katalog_aturan.csv')

print(f'Total Transaksi Komersial Bersih : {len(df_clean):,} baris')
print(f'Rentang Waktu Transaksi          : {df_clean["TGL"].min().date()} s.d. {df_clean["TGL"].max().date()} ({df_clean["TGL"].nunique()} hari aktif)')
print(f'Jumlah SKU Kanonik Unik          : {df_clean["KODE"].nunique()} SKU ({df_clean["SATUAN"].nunique()} satuan kemasan)')
print(f'Jumlah Pelanggan Outlet Bernama  : {len(df_lrfm)} outlet (+ 1 agregat walk-in CASH = {df_clean["PELANGGAN"].nunique()} entitas)')
print(f'Total Omzet Bersih (6 Bulan)     : Rp {df_clean["OMZET"].sum():,.0f}')
res1 = df_rules[['kode', 'kategori', 'tingkat', 'deskripsi', 'baris_kena', 'persen', 'tindakan']].head(14)
print("Cell 1 OK!")

# Cell 2
print("Testing Cell 2...")
cust = df_lrfm.copy()
cust['AOV'] = cust['M'] / cust['F']

stats_rows = []
for col, label in [('M', 'Monetary (Rp)'), ('F', 'Frequency (Hari)'), ('AOV', 'AOV = M/F (Rp/Hari)'), ('R', 'Recency (Hari)')]:
    q1, med, q3 = cust[col].quantile([0.25, 0.50, 0.75])
    iqr = q3 - q1
    fence_iqr = q3 + 1.5 * iqr
    fence_3sd = cust[col].mean() + 3.0 * cust[col].std()
    stats_rows.append({
        'Metrik': label,
        'Mean': cust[col].mean(), 'SD': cust[col].std(),
        'Median': med, 'IQR': iqr,
        'Pagar_1.5_IQR': fence_iqr, 'N_Outlier_IQR': int((cust[col] > fence_iqr).sum()),
        'Pagar_3_SD': fence_3sd, 'N_Outlier_3SD': int((cust[col] > fence_3sd).sum())
    })
df_stat_cust = pd.DataFrame(stats_rows)
print("Cell 2 OK!")

# Cell 3
print("Testing Cell 3...")
from sklearn.neighbors import NearestNeighbors, LocalOutlierFactor
from sklearn.preprocessing import StandardScaler
from scipy.spatial import ConvexHull

X_raw = np.column_stack([
    np.log10(cust['F']),
    np.log10(cust['M']),
    np.log10(cust['AOV']),
    cust['R'],
    cust['L']
])
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X_raw)

nn = NearestNeighbors(n_neighbors=6)
nn.fit(X_scaled)
dists, _ = nn.kneighbors(X_scaled)
cust['kNN_Dist'] = dists[:, 1:].mean(axis=1)

lof = LocalOutlierFactor(n_neighbors=5)
lof.fit_predict(X_scaled)
cust['LOF_Score'] = -lof.negative_outlier_factor_

hull = ConvexHull(cust[['F', 'M']].values)
cust['Is_ConvexHull'] = False
cust.loc[hull.vertices, 'Is_ConvexHull'] = True

top_cust = cust.sort_values(by=['LOF_Score', 'M'], ascending=False).head(12)
res3 = top_cust[['PELANGGAN', 'F', 'M', 'AOV', 'R', 'kNN_Dist', 'LOF_Score', 'Is_ConvexHull']]
print("Cell 3 OK!")

# Cell 4
print("Testing Cell 4...")
df_clean['HARGA_EFEKTIF'] = df_clean['OMZET'] / df_clean['QTY']
grp_x1 = df_clean.groupby(['KODE', 'SATUAN'])['HARGA']
med_x1 = grp_x1.transform('median')
df_clean['MEDIAN_X1'] = med_x1
df_clean['DEV_PCT_X1'] = (df_clean['HARGA'] - med_x1) / med_x1 * 100.0
df_clean['DEV_EFEKTIF_PCT'] = (df_clean['HARGA_EFEKTIF'] - med_x1) / med_x1 * 100.0

outlier_harga_kritis = df_clean[
    (df_clean['DEV_PCT_X1'].abs() > 30.0) | (df_clean['DEV_EFEKTIF_PCT'].abs() > 30.0)
][['TGL', 'PELANGGAN', 'KODE', 'NAMA_BARANG', 'SATUAN', 'QTY', 'HARGA', 'HARGA_EFEKTIF', 'MEDIAN_X1', 'DEV_EFEKTIF_PCT']]
res4 = outlier_harga_kritis.sort_values('DEV_EFEKTIF_PCT')
print("Cell 4 OK!")

# Cell 5
print("Testing Cell 5...")
log_omz = np.log10(df_clean['OMZET'])
q1_lg, q3_lg = log_omz.quantile([0.25, 0.75])
iqr_lg = q3_lg - q1_lg
fence_log_15 = 10 ** (q3_lg + 1.5 * iqr_lg)
fence_log_30 = 10 ** (q3_lg + 3.0 * iqr_lg)
res5 = df_clean.sort_values('OMZET', ascending=False)[['TGL', 'PELANGGAN', 'KODE', 'NAMA_BARANG', 'SATUAN', 'QTY', 'HARGA', 'OMZET']].head(10)
print("Cell 5 OK!")

# Cell 6
print("Testing Cell 6...")
daily = df_clean.groupby('TGL').agg(
    Jumlah_Baris=('KODE', 'count'),
    Jumlah_Nota=('PELANGGAN', 'nunique'),
    Total_QTY=('QTY', 'sum'),
    Total_Omzet=('OMZET', 'sum')
).reset_index()

med_day = daily['Total_Omzet'].median()
mad_day = np.median(np.abs(daily['Total_Omzet'] - med_day))
daily['Z_Robust_Harian'] = (daily['Total_Omzet'] - med_day) / (1.4826 * mad_day)

spikes = daily[daily['Z_Robust_Harian'] > 5.0].sort_values('Total_Omzet', ascending=False)
sunday = df_clean[df_clean['TGL'].dt.dayofweek == 6][['TGL', 'PELANGGAN', 'KODE', 'NAMA_BARANG', 'SATUAN', 'QTY', 'HARGA', 'OMZET']]
print("Cell 6 OK!")
print("ALL CELLS IN NOTEBOOK EXECUTED SUCCESSFULLY WITHOUT ANY ERRORS!")

