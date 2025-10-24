/*
 *  SVO - Simple Video Out FPGA Core
 *
 *  Copyright (C) 2014  Clifford Wolf <clifford@clifford.at>
 *  
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`timescale 1ns / 1ps
`include "svo_defines.vh"

module svo_term #(
	`SVO_DEFAULT_PARAMS,
	parameter MEM_DEPTH = 4096
) (
	// resetn clock domain: clk
	input clk, oclk, resetn,

	// input stream
	//
	// clock domain: clk
	//
	input        in_axis_tvalid,
	output       in_axis_tready,
	input  [7:0] in_axis_tdata,

	// output stream
	//   tuser[0] ... start of frame
	//
	// tdata[1:0] values:
	//   2'b00 ... no character
	//   2'b01 ... character background
	//   2'b10 ... character foreground
	//   2'b11 ... reserved
	//
	// clock domain: oclk
	//
	output       out_axis_tvalid,
	input        out_axis_tready,
	output [1:0] out_axis_tdata,
	output [0:0] out_axis_tuser
);
	`SVO_DECLS

	wire pipeline_en;

	// --------------------------------------------------------------
	// Text Memory
	// --------------------------------------------------------------

	localparam MEM_ABITS = svo_clog2(MEM_DEPTH);

	reg [7:0] mem [0:MEM_DEPTH-1];
	reg [MEM_ABITS-1:0] mem_start, mem_stop;

	// Initialize text memory with the user's message, 80 chars per line, 24x24 font
	integer init_i;
	initial begin
		// Clear only the memory we'll use - avoid synthesizer loop limit
		for (init_i = 0; init_i < 1000; init_i = init_i + 1)
			mem[init_i] = 8'h00;
		// Clear remaining with second loop
		for (init_i = 1000; init_i < 2000; init_i = init_i + 1)
			mem[init_i] = 8'h00;
		// Clear final section
		for (init_i = 2000; init_i < 2700; init_i = init_i + 1)
			mem[init_i] = 8'h00;

	// Centered lines (each line padded with spaces to center in 80 chars)
	// 14 blank lines at start for vertical centering on 1080p
	
	// Line 0-13: Blank lines (14 lines * 81 chars each = indices 0-1133)
	mem[80] = 8'h0A; mem[161] = 8'h0A; mem[242] = 8'h0A; mem[323] = 8'h0A;
	mem[404] = 8'h0A; mem[485] = 8'h0A; mem[566] = 8'h0A; mem[647] = 8'h0A;
	mem[728] = 8'h0A; mem[809] = 8'h0A; mem[890] = 8'h0A; mem[971] = 8'h0A;
	mem[1052] = 8'h0A; mem[1133] = 8'h0A;
	
	// Line 14 (1134-1214): "Sevgili Engur hocam, iyi ki yollarimiz kesismis, iyi ki"
	mem[1148] = "S"; mem[1149] = "e"; mem[1150] = "v"; mem[1151] = "g"; mem[1152] = "i"; mem[1153] = "l"; mem[1154] = "i"; mem[1155] = " "; 
	mem[1156] = "E"; mem[1157] = "n"; mem[1158] = "g"; mem[1159] = "u"; mem[1160] = "r"; mem[1161] = " "; mem[1162] = "h"; mem[1163] = "o"; 
	mem[1164] = "c"; mem[1165] = "a"; mem[1166] = "m"; mem[1167] = ","; mem[1168] = " "; mem[1169] = "i"; mem[1170] = "y"; mem[1171] = "i"; 
	mem[1172] = " "; mem[1173] = "k"; mem[1174] = "i"; mem[1175] = " "; mem[1176] = "y"; mem[1177] = "o"; mem[1178] = "l"; mem[1179] = "l"; 
	mem[1180] = "a"; mem[1181] = "r"; mem[1182] = "i"; mem[1183] = "m"; mem[1184] = "i"; mem[1185] = "z"; mem[1186] = " "; mem[1187] = "k"; 
	mem[1188] = "e"; mem[1189] = "s"; mem[1190] = "i"; mem[1191] = "s"; mem[1192] = "m"; mem[1193] = "i"; mem[1194] = "s"; mem[1195] = ","; 
	mem[1196] = " "; mem[1197] = "i"; mem[1198] = "y"; mem[1199] = "i"; mem[1200] = " "; mem[1201] = "k"; mem[1202] = "i";
	mem[1214] = 8'h0A;
	
	// Line 15 (1215-1295): "bu hayatta sizi tanima firsati yakalayan sansli kisiler"
	mem[1229] = "b"; mem[1230] = "u"; mem[1231] = " "; mem[1232] = "h"; mem[1233] = "a"; mem[1234] = "y"; mem[1235] = "a"; mem[1236] = "t"; 
	mem[1237] = "t"; mem[1238] = "a"; mem[1239] = " "; mem[1240] = "s"; mem[1241] = "i"; mem[1242] = "z"; mem[1243] = "i"; mem[1244] = " "; 
	mem[1245] = "t"; mem[1246] = "a"; mem[1247] = "n"; mem[1248] = "i"; mem[1249] = "m"; mem[1250] = "a"; mem[1251] = " "; mem[1252] = "f"; 
	mem[1253] = "i"; mem[1254] = "r"; mem[1255] = "s"; mem[1256] = "a"; mem[1257] = "t"; mem[1258] = "i"; mem[1259] = " "; mem[1260] = "y"; 
	mem[1261] = "a"; mem[1262] = "k"; mem[1263] = "a"; mem[1264] = "l"; mem[1265] = "a"; mem[1266] = "y"; mem[1267] = "a"; mem[1268] = "n"; 
	mem[1269] = " "; mem[1270] = "s"; mem[1271] = "a"; mem[1272] = "n"; mem[1273] = "s"; mem[1274] = "l"; mem[1275] = "i"; mem[1276] = " "; 
	mem[1277] = "k"; mem[1278] = "i"; mem[1279] = "s"; mem[1280] = "i"; mem[1281] = "l"; mem[1282] = "e"; mem[1283] = "r";
	mem[1295] = 8'h0A;
	
	// Line 16 (1296-1376): "arasinda yer almisim."
	mem[1321] = "a"; mem[1322] = "r"; mem[1323] = "a"; mem[1324] = "s"; mem[1325] = "i"; mem[1326] = "n"; mem[1327] = "d"; mem[1328] = "a"; 
	mem[1329] = " "; mem[1330] = "y"; mem[1331] = "e"; mem[1332] = "r"; mem[1333] = " "; mem[1334] = "a"; mem[1335] = "l"; mem[1336] = "m"; 
	mem[1337] = "i"; mem[1338] = "s"; mem[1339] = "i"; mem[1340] = "m"; mem[1341] = ".";
	mem[1376] = 8'h0A;
	
	// Line 17 (1377-1457): Blank line
	mem[1457] = 8'h0A;
	
	// Line 18 (1458-1538): "Sizden sadece teknik bilgiler degil, "hayat bilgisi""
	mem[1468] = "S"; mem[1469] = "i"; mem[1470] = "z"; mem[1471] = "d"; mem[1472] = "e"; mem[1473] = "n"; mem[1474] = " "; mem[1475] = "s"; 
	mem[1476] = "a"; mem[1477] = "d"; mem[1478] = "e"; mem[1479] = "c"; mem[1480] = "e"; mem[1481] = " "; mem[1482] = "t"; mem[1483] = "e"; 
	mem[1484] = "k"; mem[1485] = "n"; mem[1486] = "i"; mem[1487] = "k"; mem[1488] = " "; mem[1489] = "b"; mem[1490] = "i"; mem[1491] = "l"; 
	mem[1492] = "g"; mem[1493] = "i"; mem[1494] = "l"; mem[1495] = "e"; mem[1496] = "r"; mem[1497] = " "; mem[1498] = "d"; mem[1499] = "e"; 
	mem[1500] = "g"; mem[1501] = "i"; mem[1502] = "l"; mem[1503] = ","; mem[1504] = " "; mem[1505] = "\""; mem[1506] = "h"; mem[1507] = "a"; 
	mem[1508] = "y"; mem[1509] = "a"; mem[1510] = "t"; mem[1511] = " "; mem[1512] = "b"; mem[1513] = "i"; mem[1514] = "l"; mem[1515] = "g"; 
	mem[1516] = "i"; mem[1517] = "s"; mem[1518] = "i"; mem[1519] = "\"";
	mem[1538] = 8'h0A;
	
	// Line 19 (1539-1619): "diyebilecegimiz, parallelize edilemeyen, cok cok"
	mem[1550] = "d"; mem[1551] = "i"; mem[1552] = "y"; mem[1553] = "e"; mem[1554] = "b"; mem[1555] = "i"; mem[1556] = "l"; mem[1557] = "e"; 
	mem[1558] = "c"; mem[1559] = "e"; mem[1560] = "g"; mem[1561] = "i"; mem[1562] = "m"; mem[1563] = "i"; mem[1564] = "z"; mem[1565] = ","; 
	mem[1566] = " "; mem[1567] = "p"; mem[1568] = "a"; mem[1569] = "r"; mem[1570] = "a"; mem[1571] = "l"; mem[1572] = "l"; mem[1573] = "e"; 
	mem[1574] = "l"; mem[1575] = "i"; mem[1576] = "z"; mem[1577] = "e"; mem[1578] = " "; mem[1579] = "e"; mem[1580] = "d"; mem[1581] = "i"; 
	mem[1582] = "l"; mem[1583] = "e"; mem[1584] = "m"; mem[1585] = "e"; mem[1586] = "y"; mem[1587] = "e"; mem[1588] = "n"; mem[1589] = ","; 
	mem[1590] = " "; mem[1591] = "c"; mem[1592] = "o"; mem[1593] = "k"; mem[1594] = " "; mem[1595] = "c"; mem[1596] = "o"; mem[1597] = "k";
	mem[1619] = 8'h0A;
	
	// Line 20 (1620-1700): "degerli bir suru sey edindim, elimden geldikince de"
	mem[1630] = "d"; mem[1631] = "e"; mem[1632] = "g"; mem[1633] = "e"; mem[1634] = "r"; mem[1635] = "l"; mem[1636] = "i"; mem[1637] = " "; 
	mem[1638] = "b"; mem[1639] = "i"; mem[1640] = "r"; mem[1641] = " "; mem[1642] = "s"; mem[1643] = "u"; mem[1644] = "r"; mem[1645] = "u"; 
	mem[1646] = " "; mem[1647] = "s"; mem[1648] = "e"; mem[1649] = "y"; mem[1650] = " "; mem[1651] = "e"; mem[1652] = "d"; mem[1653] = "i"; 
	mem[1654] = "n"; mem[1655] = "d"; mem[1656] = "i"; mem[1657] = "m"; mem[1658] = ","; mem[1659] = " "; mem[1660] = "e"; mem[1661] = "l"; 
	mem[1662] = "i"; mem[1663] = "m"; mem[1664] = "d"; mem[1665] = "e"; mem[1666] = "n"; mem[1667] = " "; mem[1668] = "g"; mem[1669] = "e"; 
	mem[1670] = "l"; mem[1671] = "d"; mem[1672] = "i"; mem[1673] = "g"; mem[1674] = "i"; mem[1675] = "n"; mem[1676] = "c"; mem[1677] = "e"; 
	mem[1678] = " "; mem[1679] = "d"; mem[1680] = "e";
	mem[1700] = 8'h0A;
	
	// Line 21 (1701-1781): "edinmeye devam edecegim."
	mem[1724] = "e"; mem[1725] = "d"; mem[1726] = "i"; mem[1727] = "n"; mem[1728] = "m"; mem[1729] = "e"; mem[1730] = "y"; mem[1731] = "e"; 
	mem[1732] = " "; mem[1733] = "d"; mem[1734] = "e"; mem[1735] = "v"; mem[1736] = "a"; mem[1737] = "m"; mem[1738] = " "; mem[1739] = "e"; 
	mem[1740] = "d"; mem[1741] = "e"; mem[1742] = "c"; mem[1743] = "e"; mem[1744] = "g"; mem[1745] = "i"; mem[1746] = "m"; mem[1747] = ".";
	mem[1781] = 8'h0A;
	
	// Line 22 (1782-1862): Blank line
	mem[1862] = 8'h0A;
	
	// Line 23 (1863-1943): "Kendi bilgilerinizi hicbir karsilik beklemeden,"
	mem[1873] = "K"; mem[1874] = "e"; mem[1875] = "n"; mem[1876] = "d"; mem[1877] = "i"; mem[1878] = " "; mem[1879] = "b"; mem[1880] = "i"; 
	mem[1881] = "l"; mem[1882] = "g"; mem[1883] = "i"; mem[1884] = "l"; mem[1885] = "e"; mem[1886] = "r"; mem[1887] = "i"; mem[1888] = "n"; 
	mem[1889] = "i"; mem[1890] = "z"; mem[1891] = "i"; mem[1892] = " "; mem[1893] = "h"; mem[1894] = "i"; mem[1895] = "c"; mem[1896] = "b"; 
	mem[1897] = "i"; mem[1898] = "r"; mem[1899] = " "; mem[1900] = "k"; mem[1901] = "a"; mem[1902] = "r"; mem[1903] = "s"; mem[1904] = "i"; 
	mem[1905] = "l"; mem[1906] = "i"; mem[1907] = "k"; mem[1908] = " "; mem[1909] = "b"; mem[1910] = "e"; mem[1911] = "k"; mem[1912] = "l"; 
	mem[1913] = "e"; mem[1914] = "m"; mem[1915] = "e"; mem[1916] = "d"; mem[1917] = "e"; mem[1918] = "n"; mem[1919] = ",";
	mem[1943] = 8'h0A;
	
	// Line 24 (1944-2024): "sabirla bizim deanlamamizi saglamaya calistiginiz icin"
	mem[1955] = "s"; mem[1956] = "a"; mem[1957] = "b"; mem[1958] = "i"; mem[1959] = "r"; mem[1960] = "l"; mem[1961] = "a"; mem[1962] = " "; 
	mem[1963] = "b"; mem[1964] = "i"; mem[1965] = "z"; mem[1966] = "i"; mem[1967] = "m"; mem[1968] = " "; mem[1969] = "d"; mem[1970] = "e"; 
	mem[1971] = "a"; mem[1972] = "n"; mem[1973] = "l"; mem[1974] = "a"; mem[1975] = "m"; mem[1976] = "a"; mem[1977] = "m"; mem[1978] = "i"; 
	mem[1979] = "z"; mem[1980] = "i"; mem[1981] = " "; mem[1982] = "s"; mem[1983] = "a"; mem[1984] = "g"; mem[1985] = "l"; mem[1986] = "a"; 
	mem[1987] = "m"; mem[1988] = "a"; mem[1989] = "y"; mem[1990] = "a"; mem[1991] = " "; mem[1992] = "c"; mem[1993] = "a"; mem[1994] = "l"; 
	mem[1995] = "i"; mem[1996] = "s"; mem[1997] = "t"; mem[1998] = "i"; mem[1999] = "g"; mem[2000] = "i"; mem[2001] = "n"; mem[2002] = "i"; 
	mem[2003] = "z"; mem[2004] = " "; mem[2005] = "i"; mem[2006] = "c"; mem[2007] = "i"; mem[2008] = "n";
	mem[2024] = 8'h0A;
	
	// Line 25 (2025-2105): "kendim basta olmak uzere tum ogrencileriniz adina"
	mem[2034] = "k"; mem[2035] = "e"; mem[2036] = "n"; mem[2037] = "d"; mem[2038] = "i"; mem[2039] = "m"; mem[2040] = " "; mem[2041] = "b"; 
	mem[2042] = "a"; mem[2043] = "s"; mem[2044] = "t"; mem[2045] = "a"; mem[2046] = " "; mem[2047] = "o"; mem[2048] = "l"; mem[2049] = "m"; 
	mem[2050] = "a"; mem[2051] = "k"; mem[2052] = " "; mem[2053] = "u"; mem[2054] = "z"; mem[2055] = "e"; mem[2056] = "r"; mem[2057] = "e"; 
	mem[2058] = " "; mem[2059] = "t"; mem[2060] = "u"; mem[2061] = "m"; mem[2062] = " "; mem[2063] = "o"; mem[2064] = "g"; mem[2065] = "r"; 
	mem[2066] = "e"; mem[2067] = "n"; mem[2068] = "c"; mem[2069] = "i"; mem[2070] = "l"; mem[2071] = "e"; mem[2072] = "r"; mem[2073] = "i"; 
	mem[2074] = "n"; mem[2075] = "i"; mem[2076] = "z"; mem[2077] = " "; mem[2078] = "a"; mem[2079] = "d"; mem[2080] = "i"; mem[2081] = "n"; 
	mem[2082] = "a";
	mem[2105] = 8'h0A;
	
	// Line 26 (2106-2186): "size tesekkuru borc bilirim."
	mem[2124] = "s"; mem[2125] = "i"; mem[2126] = "z"; mem[2127] = "e"; mem[2128] = " "; mem[2129] = "t"; mem[2130] = "e"; mem[2131] = "s"; 
	mem[2132] = "e"; mem[2133] = "k"; mem[2134] = "k"; mem[2135] = "u"; mem[2136] = "r"; mem[2137] = "u"; mem[2138] = " "; mem[2139] = "b"; 
	mem[2140] = "o"; mem[2141] = "r"; mem[2142] = "c"; mem[2143] = " "; mem[2144] = "b"; mem[2145] = "i"; mem[2146] = "l"; mem[2147] = "i"; 
	mem[2148] = "r"; mem[2149] = "i"; mem[2150] = "m"; mem[2151] = ".";
	mem[2186] = 8'h0A;
	
	// Line 27 (2187-2267): Blank line
	mem[2267] = 8'h0A;
	
	// Line 28 (2268-2348): "Iyi ki dogdunuz, iyi bizim hocamizsiniz."
	mem[2286] = "I"; mem[2287] = "y"; mem[2288] = "i"; mem[2289] = " "; mem[2290] = "k"; mem[2291] = "i"; mem[2292] = " "; mem[2293] = "d"; 
	mem[2294] = "o"; mem[2295] = "g"; mem[2296] = "d"; mem[2297] = "u"; mem[2298] = "n"; mem[2299] = "u"; mem[2300] = "z"; mem[2301] = ","; 
	mem[2302] = " "; mem[2303] = "i"; mem[2304] = "y"; mem[2305] = "i"; mem[2306] = " "; mem[2307] = "b"; mem[2308] = "i"; mem[2309] = "z"; 
	mem[2310] = "i"; mem[2311] = "m"; mem[2312] = " "; mem[2313] = "h"; mem[2314] = "o"; mem[2315] = "c"; mem[2316] = "a"; mem[2317] = "m"; 
	mem[2318] = "i"; mem[2319] = "z"; mem[2320] = "s"; mem[2321] = "i"; mem[2322] = "n"; mem[2323] = "i"; mem[2324] = "z"; mem[2325] = ".";
	mem[2348] = 8'h0A;
	
	// Line 29 (2349-2429): "Nice seneler,"
	mem[2382] = "N"; mem[2383] = "i"; mem[2384] = "c"; mem[2385] = "e"; mem[2386] = " "; mem[2387] = "s"; mem[2388] = "e"; mem[2389] = "n"; 
	mem[2390] = "e"; mem[2391] = "l"; mem[2392] = "e"; mem[2393] = "r"; mem[2394] = ",";
	mem[2429] = 8'h0A;
	
	// Line 30 (2430-2510): "Omur boyu ogrenciiniz"
	mem[2460] = "O"; mem[2461] = "m"; mem[2462] = "u"; mem[2463] = "r"; mem[2464] = " "; mem[2465] = "b"; mem[2466] = "o"; mem[2467] = "y"; 
	mem[2468] = "u"; mem[2469] = " "; mem[2470] = "o"; mem[2471] = "g"; mem[2472] = "r"; mem[2473] = "e"; mem[2474] = "n"; mem[2475] = "c"; 
	mem[2476] = "i"; mem[2477] = "n"; mem[2478] = "i"; mem[2479] = "z";
	mem[2510] = 8'h0A;
	
	// Line 31 (2511-2591): "Basar Subasi"
	mem[2545] = "B"; mem[2546] = "a"; mem[2547] = "s"; mem[2548] = "a"; mem[2549] = "r"; mem[2550] = " "; mem[2551] = "S"; mem[2552] = "u"; 
	mem[2553] = "b"; mem[2554] = "a"; mem[2555] = "s"; mem[2556] = "i";
	mem[2591] = 8'h0A;
	
	// Line 32 (2592-2672): "2025"
	mem[2630] = "2"; mem[2631] = "0"; mem[2632] = "2"; mem[2633] = "5";
	end

	reg [MEM_ABITS-1:0] mem_portA_addr;
	reg [7:0] mem_portA_rdata;
	reg [7:0] mem_portA_wdata;
	reg mem_portA_wen;

	reg [MEM_ABITS-1:0] mem_portB_addr;
	reg [7:0] mem_portB_rdata;

	reg [MEM_ABITS-1:0] mem_start_GR, mem_stop_GR;
	reg [MEM_ABITS-1:0] mem_start_B1, mem_stop_B1;
	reg [MEM_ABITS-1:0] mem_start_B2, mem_stop_B2;
	reg [MEM_ABITS-1:0] mem_start_B3, mem_stop_B3;
	reg [MEM_ABITS-1:0] mem_start_B,  mem_stop_B;

	function [MEM_ABITS-1:0] mem_bin2gray(input [MEM_ABITS-1:0] in);
		integer i;
		reg [MEM_ABITS:0] temp;
		begin
			temp = in;
			for (i=0; i<MEM_ABITS; i=i+1)
				mem_bin2gray[i] = ^temp[i +: 2];
		end
	endfunction

	function [MEM_ABITS-1:0] mem_gray2bin(input [MEM_ABITS-1:0] in);
		integer i;
		begin
			for (i=0; i<MEM_ABITS; i=i+1)
				mem_gray2bin[i] = ^(in >> i);
		end
	endfunction

	always @(posedge clk) begin
		if (mem_portA_wen) begin
			mem_portA_rdata <= 'bx;
			mem[mem_portA_addr] <= mem_portA_wdata;
		end else begin
			mem_portA_rdata <= mem[mem_portA_addr];
		end

		mem_start_GR <= mem_bin2gray(mem_start);
		mem_stop_GR <= mem_bin2gray(mem_stop);
	end

	always @(posedge oclk) begin
		if (pipeline_en)
			mem_portB_rdata <= mem_portB_addr != mem_stop_B ? mem[mem_portB_addr] : 0;

		mem_start_B1 <= mem_start_GR;
		mem_start_B2 <= mem_start_B1;
		mem_start_B3 <= mem_gray2bin(mem_start_B2);

		mem_stop_B1 <= mem_stop_GR;
		mem_stop_B2 <= mem_stop_B1;
		mem_stop_B3 <= mem_gray2bin(mem_stop_B2);
	end


	// --------------------------------------------------------------
	// Input Interface
	// --------------------------------------------------------------

	reg request_remove_line_oclk;
	reg request_remove_line_syn1;
	reg request_remove_line_syn2;
	reg request_remove_line_syn3;
	reg request_remove_line;

	always @(posedge clk) begin
		request_remove_line_syn1 <= request_remove_line_oclk;
		request_remove_line_syn2 <= request_remove_line_syn1;
		request_remove_line_syn3 <= request_remove_line_syn2;
		request_remove_line <= request_remove_line_syn2 != request_remove_line_syn3;
	end

	reg remove_line;
	wire [MEM_ABITS-1:0] next_mem_start, next_mem_stop;
	assign next_mem_start = mem_start == MEM_DEPTH-1 ? 0 : mem_start + 1;
	assign next_mem_stop = mem_stop == MEM_DEPTH-1 ? 0 : mem_stop + 1;
	assign in_axis_tready = next_mem_stop != mem_start && !remove_line;

	always @(posedge clk) begin
		mem_portA_wen <= 0;
		mem_portA_wdata <= in_axis_tdata;
		mem_portA_addr <= mem_start;

		if (request_remove_line && mem_start != mem_stop) begin
			mem_portA_addr <= next_mem_start;
			mem_start <= next_mem_start;
			remove_line <= 1;
		end

		if (!resetn) begin
			remove_line <= 0;
			mem_start <= 0;
			mem_stop <= 2634;  // Set to last used index + 1
		end else begin
			if (remove_line) begin
				if (mem_portA_rdata == "\n" || mem_start == mem_stop) begin
					remove_line <= 0;
				end else begin
					mem_portA_addr <= next_mem_start;
					mem_start <= next_mem_start;
				end
			end else
			if (next_mem_stop == mem_start) begin
				if (mem_portA_addr == mem_start) begin
					mem_portA_addr <= next_mem_start;
					mem_start <= next_mem_start;
					remove_line <= 1;
				end
			end else
			if (in_axis_tvalid && in_axis_tready) begin
				if (in_axis_tdata >= 32 || in_axis_tdata == "\n") begin
					mem_stop <= next_mem_stop;
					mem_portA_addr <= mem_stop;
					mem_portA_wen <= 1;
				end else
				if (in_axis_tdata == 4) begin
					// EOT clears the screen
					mem_stop <= mem_start;
				end else
				if (in_axis_tdata == 8) begin
					// BS removes the last char
					if (mem_stop != mem_start)
						mem_stop <= mem_stop == 0 ? MEM_DEPTH-1 : mem_stop-1;
				end
			end
		end
	end


	// --------------------------------------------------------------
	// Font Memory
	// --------------------------------------------------------------

	localparam [8191:0] fontmem = {
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b01100000, 8'b10010010, 8'b00001100, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00001100, 8'b00010000, 8'b00010000, 8'b00100000, 8'b00010000, 8'b00010000, 8'b00001100,
		8'b00000000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000,
		8'b00000000, 8'b00110000, 8'b00001000, 8'b00001000, 8'b00000100, 8'b00001000, 8'b00001000, 8'b00110000,
		8'b00000000, 8'b00111100, 8'b00001000, 8'b00010000, 8'b00100000, 8'b00111100, 8'b00000000, 8'b00000000,
		8'b00111000, 8'b01000000, 8'b01110000, 8'b01001000, 8'b01001000, 8'b01001000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b01000100, 8'b00101000, 8'b00010000, 8'b00101000, 8'b01000100, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b01000100, 8'b10101010, 8'b10010010, 8'b10000010, 8'b10000010, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00010000, 8'b00101000, 8'b01000100, 8'b01000100, 8'b01000100, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b01011000, 8'b00100100, 8'b00100100, 8'b00100100, 8'b00100100, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00111000, 8'b00010000, 8'b00000000,
		8'b00000000, 8'b00011100, 8'b00100000, 8'b00011000, 8'b00000100, 8'b00111000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000100, 8'b00000100, 8'b00000100, 8'b00001100, 8'b00110100, 8'b00000000, 8'b00000000,
		8'b00100000, 8'b00100000, 8'b00111000, 8'b00100100, 8'b00100100, 8'b01011000, 8'b00000000, 8'b00000000,
		8'b00001000, 8'b00001000, 8'b00111000, 8'b01001000, 8'b01001000, 8'b00110100, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000100, 8'b01000100, 8'b00111000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b01001000, 8'b01001000, 8'b01001000, 8'b01001000, 8'b00110100, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b10000010, 8'b10000010, 8'b10010010, 8'b10010010, 8'b01101101, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00011000,
		8'b00000000, 8'b00100100, 8'b00010100, 8'b00001100, 8'b00010100, 8'b00100100, 8'b00000100, 8'b00000100,
		8'b00001100, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00000000, 8'b00010000, 8'b00000000,
		8'b00000000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00000000, 8'b00010000, 8'b00000000,
		8'b00000000, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01001100, 8'b00110100, 8'b00000100, 8'b00000100,
		8'b00111000, 8'b01000000, 8'b01111000, 8'b01000100, 8'b01000100, 8'b10111000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00011100, 8'b00001000, 8'b01001000, 8'b00110000,
		8'b00000000, 8'b00111000, 8'b00000100, 8'b01111100, 8'b01000100, 8'b00111000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b10110000, 8'b01001000, 8'b01001000, 8'b01001000, 8'b01110000, 8'b01000000, 8'b01000000,
		8'b00000000, 8'b00111000, 8'b00000100, 8'b00000100, 8'b00000100, 8'b00111000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00110100, 8'b01001000, 8'b01001000, 8'b01001000, 8'b00111000, 8'b00001000, 8'b00001000,
		8'b00000000, 8'b10111000, 8'b01000100, 8'b01000100, 8'b01111000, 8'b01000000, 8'b00111000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00010000, 8'b00001000,
		8'b11111110, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b01000100, 8'b00101000, 8'b00010000,
		8'b00000000, 8'b00111000, 8'b00100000, 8'b00100000, 8'b00100000, 8'b00100000, 8'b00100000, 8'b00111000,
		8'b00000000, 8'b10000000, 8'b01000000, 8'b00100000, 8'b00010000, 8'b00001000, 8'b00000100, 8'b00000010,
		8'b00000000, 8'b00111000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00111000,
		8'b00000000, 8'b01111100, 8'b00000100, 8'b00001000, 8'b00010000, 8'b00100000, 8'b01000000, 8'b01111100,
		8'b00000000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00101000, 8'b01000100, 8'b01000100,
		8'b00000000, 8'b01000100, 8'b01000100, 8'b00101000, 8'b00010000, 8'b00101000, 8'b01000100, 8'b01000100,
		8'b00000000, 8'b00101000, 8'b00101000, 8'b01010100, 8'b01010100, 8'b10000010, 8'b10000010, 8'b10000010,
		8'b00000000, 8'b00010000, 8'b00010000, 8'b00101000, 8'b00101000, 8'b01000100, 8'b01000100, 8'b01000100,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01000100,
		8'b00000000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b01111100,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000000, 8'b00111000, 8'b00000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b01000100, 8'b00100100, 8'b00010100, 8'b00111100, 8'b01000100, 8'b01000100, 8'b00111100,
		8'b01100000, 8'b00111000, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00111000, 8'b01001000, 8'b01001000, 8'b00111000,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b01000100, 8'b01000100, 8'b01100100, 8'b01010100, 8'b01010100, 8'b01001100, 8'b01000100,
		8'b00000000, 8'b10000010, 8'b10000010, 8'b10000010, 8'b10010010, 8'b10101010, 8'b11000110, 8'b10000010,
		8'b00000000, 8'b01111000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00001000,
		8'b00000000, 8'b01000100, 8'b01000100, 8'b00100100, 8'b00011100, 8'b00100100, 8'b01000100, 8'b01000100,
		8'b00000000, 8'b00011000, 8'b00100100, 8'b00100100, 8'b00100000, 8'b00100000, 8'b00100000, 8'b01110000,
		8'b00000000, 8'b00111000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00111000,
		8'b00000000, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01111100, 8'b01000100, 8'b01000100, 8'b01000100,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000100, 8'b01110100, 8'b00000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00000100, 8'b00000100, 8'b00000100, 8'b01111100, 8'b00000100, 8'b00000100, 8'b01111100,
		8'b00000000, 8'b01111100, 8'b00000100, 8'b00000100, 8'b00111100, 8'b00000100, 8'b00000100, 8'b01111100,
		8'b00000000, 8'b00111100, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01000100, 8'b00111100,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b00000100, 8'b00000100, 8'b00000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00111100, 8'b01000100, 8'b01000100, 8'b00111100, 8'b01000100, 8'b01000100, 8'b00111100,
		8'b00000000, 8'b01000100, 8'b01000100, 8'b01000100, 8'b01111100, 8'b01000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00111000, 8'b00000100, 8'b01110100, 8'b01010100, 8'b01110100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00010000, 8'b00000000, 8'b00010000, 8'b00100000, 8'b01000000, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00000100, 8'b00001000, 8'b00010000, 8'b00100000, 8'b00010000, 8'b00001000, 8'b00000100,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b11111110, 8'b00000000, 8'b11111110, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00100000, 8'b00010000, 8'b00001000, 8'b00000100, 8'b00001000, 8'b00010000, 8'b00100000,
		8'b00010000, 8'b00100000, 8'b00110000, 8'b00110000, 8'b00000000, 8'b00110000, 8'b00110000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00110000, 8'b00110000, 8'b00000000, 8'b00110000, 8'b00110000, 8'b00000000,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000000, 8'b01111000, 8'b01000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000100, 8'b00111000, 8'b01000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00010000, 8'b00100000, 8'b01000000, 8'b01111100,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000100, 8'b00111100, 8'b00000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000000, 8'b00111100, 8'b00000100, 8'b00000100, 8'b01111100,
		8'b00000000, 8'b01110000, 8'b00100000, 8'b00100000, 8'b01111100, 8'b00100100, 8'b00101000, 8'b00110000,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000000, 8'b00110000, 8'b01000000, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b01111100, 8'b00001000, 8'b00010000, 8'b00100000, 8'b01000000, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00111000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00011000, 8'b00010000,
		8'b00000000, 8'b00111000, 8'b01000100, 8'b01000100, 8'b01010100, 8'b01000100, 8'b01000100, 8'b00111000,
		8'b00000000, 8'b00000010, 8'b00000100, 8'b00001000, 8'b00010000, 8'b00100000, 8'b01000000, 8'b10000000,
		8'b00000000, 8'b00110000, 8'b00110000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b11111110, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00010000, 8'b00100000, 8'b00110000, 8'b00110000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b11111110, 8'b00010000, 8'b00010000, 8'b00010000,
		8'b00000000, 8'b00010000, 8'b10010010, 8'b01010100, 8'b00111000, 8'b01010100, 8'b10010010, 8'b00010000,
		8'b00000000, 8'b00001000, 8'b00010000, 8'b00100000, 8'b00100000, 8'b00100000, 8'b00010000, 8'b00001000,
		8'b00000000, 8'b00100000, 8'b00010000, 8'b00001000, 8'b00001000, 8'b00001000, 8'b00010000, 8'b00100000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00010000, 8'b00010000,
		8'b00000000, 8'b01011100, 8'b00100010, 8'b01100010, 8'b00010100, 8'b00001000, 8'b00010100, 8'b00011000,
		8'b00000000, 8'b00000000, 8'b01100100, 8'b01101000, 8'b00010000, 8'b00101100, 8'b01001100, 8'b00000000,
		8'b00000000, 8'b00010000, 8'b00111100, 8'b01010000, 8'b00111000, 8'b00010100, 8'b01111000, 8'b00010000,
		8'b00000000, 8'b00101000, 8'b00101000, 8'b11111110, 8'b00101000, 8'b11111110, 8'b00101000, 8'b00101000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00101000, 8'b00101000,
		8'b00000000, 8'b00010000, 8'b00000000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000, 8'b00010000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000,
		8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000, 8'b00000000
	};

	function font(input [7:0] c, input [2:0] x, input [2:0] y);
		font = fontmem[{c, y, x}];
	endfunction


	// --------------------------------------------------------------
	// Video Pipeline
	// --------------------------------------------------------------

	reg [3:0] oresetn_q;
	reg oresetn;

	// synchronize oresetn with oclk
	always @(posedge oclk)
		{oresetn, oresetn_q} <= {oresetn_q, resetn};

	// --------------------------------------------------------------
	// Pipeline stage 1: basic video timing (24x24 font scaling)

	reg p1_start_of_frame;
	reg p1_start_of_line;
	reg p1_valid;

	reg [`SVO_XYBITS-1:0] p1_xpos, p1_ypos;

	// For 24x24 scaling, each character cell is 24x24 pixels
	localparam CHAR_WIDTH = 24;
	localparam CHAR_HEIGHT = 24;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p1_xpos <= 0;
			p1_ypos <= 0;
			p1_valid <= 0;
		end else if (pipeline_en) begin
			p1_valid <= 1;
			p1_start_of_frame <= !p1_xpos && !p1_ypos;
			p1_start_of_line <= !p1_xpos;
			if (p1_xpos == SVO_HOR_PIXELS-1) begin
				p1_xpos <= 0;
				p1_ypos <= p1_ypos == SVO_VER_PIXELS-1 ? 0 : p1_ypos + 1;
			end else begin
				p1_xpos <= p1_xpos + 1;
			end
		end
	end

	// --------------------------------------------------------------
	// Pipeline stage 2: text memory addr generator (24x24 font scaling)

	reg [4:0] p2_x, p2_y; // up to 24
	reg [2:0] p2_font_x, p2_font_y; // 0-7 for font lookup
	reg p2_start_of_frame;
	reg p2_start_of_line;
	reg p2_valid;

	reg p2_found_end, p2_last_req_remline;
	reg [MEM_ABITS-1:0] p2_line_start_addr;
	wire [MEM_ABITS-1:0] next_mem_portB_addr;
	assign next_mem_portB_addr = mem_portB_addr == MEM_DEPTH-1 ? 0 : mem_portB_addr + 1;

	reg [7:0] p2_char_per_line;
	always @* begin
		// Number of characters per line = screen width / 24
		p2_char_per_line = SVO_HOR_PIXELS / CHAR_WIDTH;
	end

	always @(posedge oclk) begin
		if (!oresetn) begin
			p2_valid <= 0;
			p2_found_end <= 1;
			p2_last_req_remline <= 1;
			request_remove_line_oclk <= 0;
			p2_x <= 0;
			p2_y <= 0;
			p2_font_x <= 0;
			p2_font_y <= 0;
		end else if (pipeline_en) begin
			p2_start_of_frame <= p1_start_of_frame;
			p2_start_of_line <= p1_start_of_line;
			p2_valid <= p1_valid;

			if (mem_portB_addr == mem_stop_B)
				p2_found_end <= 1;

			// Map pixel position to character and font pixel
			if (p1_start_of_frame) begin
				if (!p2_found_end && !p2_last_req_remline) begin
					request_remove_line_oclk <= ~request_remove_line_oclk;
					p2_last_req_remline <= 1;
				end else
					p2_last_req_remline <= 0;

				mem_stop_B <= mem_stop_B3;
				mem_start_B <= mem_start_B3;
				mem_portB_addr <= mem_start_B3;
				p2_line_start_addr <= mem_start_B3;
				p2_found_end <= 0;
				p2_x <= 0;
				p2_y <= 0;
				p2_font_x <= 0;
				p2_font_y <= 0;
			end else if (p1_start_of_line) begin
				if (p2_font_y == 23) begin
					// End of character cell row, move to next text line
					if (mem_portB_addr != mem_stop_B) begin
						mem_portB_addr <= next_mem_portB_addr;
						p2_line_start_addr <= next_mem_portB_addr;
					end else begin
						p2_line_start_addr <= mem_stop_B;
					end
					p2_font_y <= 0;
				end else begin
					mem_portB_addr <= p2_line_start_addr;
					p2_font_y <= p2_font_y + 1;
				end
				p2_x <= 0;
				p2_font_x <= 0;
			end else begin
				if (p2_font_x == 23) begin
					// End of character cell column, move to next character
					if (mem_portB_addr != mem_stop_B && mem_portB_rdata != "\n")
						mem_portB_addr <= next_mem_portB_addr;
					p2_font_x <= 0;
				end else begin
					p2_font_x <= p2_font_x + 1;
				end
				p2_x <= p2_x + 1;
			end
		end
	end

	// --------------------------------------------------------------
	// Pipeline stage 3: wait for memory (pass through font_x/font_y)

	reg [4:0] p3_x, p3_y;
	reg [2:0] p3_font_x, p3_font_y;
	reg p3_start_of_frame;
	reg p3_start_of_line;
	reg p3_valid;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p3_valid <= 0;
		end else if (pipeline_en) begin
			p3_x <= p2_x;
			p3_y <= p2_y;
			p3_font_x <= p2_font_x;
			p3_font_y <= p2_font_y;
			p3_start_of_frame <= p2_start_of_frame;
			p3_start_of_line <= p2_start_of_line;
			p3_valid <= p2_valid;
		end
	end

	// --------------------------------------------------------------
	// Pipeline stage 4: read char (pass through font_x/font_y)

	reg [7:0] p4_c;
	reg [4:0] p4_x, p4_y;
	reg [2:0] p4_font_x, p4_font_y;
	reg p4_start_of_frame;
	reg p4_valid;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p4_valid <= 0;
		end else if (pipeline_en) begin
			p4_c <= mem_portB_rdata;
			p4_x <= p3_x;
			p4_y <= p3_y;
			p4_font_x <= p3_font_x;
			p4_font_y <= p3_font_y;
			p4_start_of_frame <= p3_start_of_frame;
			p4_valid <= p3_valid;
		end
	end

	// --------------------------------------------------------------
	// Pipeline stage 5: font lookup (24x24 scaling)

	reg [1:0] p5_outval;
	reg p5_start_of_frame;
	reg p5_valid;

	always @(posedge oclk) begin
		if (!oresetn) begin
			p5_valid <= 0;
		end else if (pipeline_en) begin
			if (32 <= p4_c && p4_c < 128)
				// Scale: map 0-23 to 0-7 by dividing by 3
				p5_outval <= font(p4_c, p4_font_x / 3, p4_font_y / 3) ? 2'b10 : 2'b01;
			else
				p5_outval <= 0;
			p5_start_of_frame <= p4_start_of_frame;
			p5_valid <= p4_valid;
		end
	end

	// --------------------------------------------------------------
	// Pipeline output stage

	assign pipeline_en = !p5_valid || out_axis_tready;

	assign out_axis_tvalid = p5_valid;
	assign out_axis_tdata = p5_outval;
	assign out_axis_tuser = p5_start_of_frame;
endmodule

