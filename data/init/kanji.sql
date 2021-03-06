PRAGMA foreign_keys = ON;

CREATE TABLE kanji(
    id STRING PRIMARY KEY,
    stroke INTEGER
);


-- Insert Kanji not listed in kanjidic2
INSERT INTO kanji VALUES('｜', 1);
INSERT INTO kanji VALUES('ノ', 1);
INSERT INTO kanji VALUES('ハ', 2);
INSERT INTO kanji VALUES('マ', 2);
INSERT INTO kanji VALUES('ユ', 2);
INSERT INTO kanji VALUES('ヨ', 3);


CREATE VIEW radical AS
SELECT id, stroke FROM kanji WHERE id IN (
'一','｜','丶','ノ','乙','亅','二','亠','人','化','个','儿','入','ハ','并','冂','冖','冫','几','凵',
'刀','刈','力','勹','匕','匚','十','卜','卩','厂','厶','又','マ','九','ユ','乃','込','口','囗','土',
'士','夂','夕','大','女','子','宀','寸','小','尚','尢','尸','屮','山','川','巛','工','已','巾','干',
'幺','广','廴','廾','弋','弓','ヨ','彑','彡','彳','忙','扎','汁','犯','艾','邦','阡','也','亡','及',
'久','老','心','戈','戸','手','支','攵','文','斗','斤','方','无','日','曰','月','木','欠','止','歹',
'殳','比','毛','氏','气','水','火','杰','爪','父','爻','爿','片','牛','犬','礼','王','元','井','勿',
'尤','五','屯','巴','毋','玄','瓦','甘','生','用','田','疋','疔','癶','白','皮','皿','目','矛','矢',
'石','示','禹','禾','穴','立','初','世','巨','冊','母','買','牙','瓜','竹','米','糸','缶','羊','羽',
'而','耒','耳','聿','肉','自','至','臼','舌','舟','艮','色','虍','虫','血','行','衣','西','臣','見',
'角','言','谷','豆','豕','豸','貝','赤','走','足','身','車','辛','辰','酉','釆','里','舛','麦','金',
'長','門','隶','隹','雨','青','非','奄','岡','免','斉','面','革','韭','音','頁','風','飛','食','首',
'香','品','馬','骨','高','髟','鬥','鬯','鬲','鬼','竜','韋','魚','鳥','鹵','鹿','麻','亀','滴','黄',
'黒','黍','黹','無','歯','黽','鼎','鼓','鼠','鼻','齊','龠');

CREATE TABLE kanji_radical(
    id_kanji STRING,
    id_radical STRING,
    FOREIGN KEY(id_kanji) REFERENCES kanji(id),
    FOREIGN KEY(id_radical) REFERENCES radical(id),
    PRIMARY KEY (id_kanji, id_radical)
);

CREATE TABLE on_yomi(
    id INTEGER PRIMARY KEY,
    id_kanji STRING,
    reading STRING,
    FOREIGN KEY(id_kanji) REFERENCES kanji(id)
);

CREATE TABLE kun_yomi(
    id INTEGER PRIMARY KEY,
    id_kanji STRING,
    reading STRING,
    FOREIGN KEY(id_kanji) REFERENCES kanji(id)
);

create table meaning(
    id INTEGER PRIMARY KEY,
    id_kanji INTEGER,
    meaning STRING,
    lang STRING
);
