class_name GameData
extends RefCounted

const SAVE_PATH = "user://lumenwild_save.json"
const CHARACTERS = [
	{"name": "岚羽", "element": "风", "title": "循风的旅人", "color": Color("71e4c4"), "dark": Color("287c70"), "skill": "回风刃", "burst": "千风回响", "weapon": "长剑", "description": "风铃村的送信人，能听见风里未送达的信。", "ability": "聚拢气流斩击，扩散敌人身上的元素。", "cooldown": 5.0},
	{"name": "朱烬", "element": "焰", "title": "不熄的星火", "color": Color("ffac72"), "dark": Color("b94c3d"), "skill": "流火", "burst": "赤日燎原", "weapon": "重刃", "description": "灰烬工坊的年轻匠人，用火种修补破碎的世界。", "ability": "投出炽焰，留下灼烧；与潮引发蒸腾。", "cooldown": 6.0},
	{"name": "澜音", "element": "潮", "title": "听潮的歌者", "color": Color("82dafa"), "dark": Color("397cb1"), "skill": "潮汐环", "burst": "深海之歌", "weapon": "法器", "description": "从沉没旧城归来的歌者，记忆随潮水苏醒。", "ability": "涌起水环并恢复生命；与雷引发感电。", "cooldown": 8.0},
	{"name": "霁霆", "element": "雷", "title": "追逐暴风的人", "color": Color("cfb0ff"), "dark": Color("7359b6"), "skill": "闪雷", "burst": "天隙轰鸣", "weapon": "长枪", "description": "离开观星台的巡夜人，正在追寻失踪的导师。", "ability": "雷光贯穿前方；与焰引发超载冲击。", "cooldown": 6.0},
	{"name": "砾川", "element": "岩", "title": "山脉的守望者", "color": Color("f4d383"), "dark": Color("9d7950"), "skill": "磐石护身", "burst": "群山应答", "weapon": "战锤", "description": "遗迹中醒来的石之守卫，守护一份古老的约定。", "ability": "震地并获得护盾；结晶反应加固护盾。", "cooldown": 10.0}
]

const LIMITED_CHARACTERS = [
	{"name": "栖月", "element": "风", "element_id": 0, "title": "长夜的引航星", "color": Color("b6f5de"), "dark": Color("335d78"), "skill": "月轮归航", "burst": "星河之庭", "weapon": "月刃", "description": "穿越云海的引航者，以月轮收束散落的风。", "ability": "往返月轮双段命中，归返治疗；爆发生成持续风域。", "cooldown": 7.0, "banner": "月渡千帆", "tagline": "让晚风，带你去星光亮起的地方。"},
	{"name": "绯曜", "element": "焰", "element_id": 1, "title": "落日之后的黎明", "color": Color("ffbf82"), "dark": Color("943c56"), "skill": "灼羽突进", "burst": "不落之凰", "weapon": "焰双刃", "description": "守护旧日灯塔的焰之剑士，从灰烬中带回第一道晨光。", "ability": "火焰突进留下焰尾并获护盾；凤凰俯冲后灼烧地面。", "cooldown": 8.0, "banner": "不落的赤羽", "tagline": "哪怕长夜不尽，我也会再点一盏灯。"},
	{"name": "镜夜", "element": "雷", "element_id": 3, "title": "星隙中的裁决", "color": Color("d3bfff"), "dark": Color("483a78"), "skill": "折光连闪", "burst": "天隙裁星", "weapon": "星槊", "description": "在破碎星图之间巡行的执灯者，以雷光划开无声的夜。", "ability": "雷击连锁四个目标并留雷印；三轮落雷对雷印增伤。", "cooldown": 7.0, "banner": "星隙裁夜", "tagline": "在雷光落下之前，听见群星的回答。"}
]

const CHAPTER_CHARACTERS = [
	{"name": "沧璃", "element": "潮", "element_id": 2, "title": "深蓝海路的领航者", "color": Color("8ce9ff"), "dark": Color("245d85"), "skill": "溯流珠", "burst": "万潮归心", "weapon": "潮珠", "description": "从沉没港口归来的领航者，用流光为迷航者画出海路。", "ability": "三枚水珠轮番追击并治疗；潮汐漩涡持续聚敌。", "cooldown": 8.0, "banner": "海路拾光", "tagline": "即使海路被遗忘，潮汐仍记得归途。"},
	{"name": "砚山", "element": "岩", "element_id": 4, "title": "写下群峰的人", "color": Color("ebcd94"), "dark": Color("646454"), "skill": "镇山印", "burst": "千嶂鸣", "weapon": "石印", "description": "以群山为纸的行游刻师，将守护的承诺刻进石印。", "ability": "展开护盾并震地；六座岩柱共鸣，震击三次。", "cooldown": 9.0, "banner": "千山入卷", "tagline": "一笔落下，便是一座为你挡风的山。"},
	{"name": "烬翎", "element": "焰", "element_id": 1, "title": "灰烬里的信使", "color": Color("ff996d"), "dark": Color("794852"), "skill": "翎火掠", "burst": "赤羽焚天", "weapon": "羽刃", "description": "穿越旧港火海的信使，把未烧尽的信递向黎明。", "ability": "羽刃突进与护盾；强化凤凰俯冲，燃起持续火场。", "cooldown": 8.0, "banner": "寄往黎明", "tagline": "火会熄灭，送达的约定不会。"},
	{"name": "霜汐", "element": "潮", "element_id": 2, "title": "月下的听海人", "color": Color("c0f1f8"), "dark": Color("516487"), "skill": "月露珠", "burst": "静海回澜", "weapon": "月露", "description": "守在北岸的听海人，从寂静水面辨认远航者的脚步。", "ability": "三枚月露追击，每次恢复更多生命；潮域持续牵引。", "cooldown": 8.0, "banner": "月照潮生", "tagline": "海面安静下来时，就能听见你的回答。"},
	{"name": "朔风", "element": "风", "element_id": 0, "title": "穿越长冬的旅人", "color": Color("a5e6d4"), "dark": Color("4d697c"), "skill": "朔月刃", "burst": "长风渡", "weapon": "风轮", "description": "来自北境的旅人，把最后一缕暖风藏在行囊里。", "ability": "强化往返风刃，归返治疗；风域聚敌并持续恢复。", "cooldown": 7.0, "banner": "风过长冬", "tagline": "走过冬天的人，总会认出春天。"},
	{"name": "玄霆", "element": "雷", "element_id": 3, "title": "无声风暴的守望者", "color": Color("b7baff"), "dark": Color("3e536e"), "skill": "玄电锁", "burst": "雷幕天衡", "weapon": "雷枪", "description": "曾守护旧观星台的巡卫，在寂夜中倾听未至的雷鸣。", "ability": "四段连锁留下雷印；强化三轮落雷引发雷印共鸣。", "cooldown": 7.0, "banner": "寂夜闻雷", "tagline": "天空沉默的时候，我替它守夜。"},
	{"name": "曜岚", "element": "风", "element_id": 0, "title": "群星归途的引路者", "color": Color("e5f7ad"), "dark": Color("54785c"), "skill": "流星环", "burst": "天风星庭", "weapon": "星环", "description": "拾起破碎的星图，让归航的风穿过每一扇窗。", "ability": "星环往返追击；更宽的十秒风域，五次治疗脉冲。", "cooldown": 7.0, "banner": "群星赴约", "tagline": "你点亮的每一盏灯，都成了归航的星。"},
	{"name": "丹砂", "element": "岩", "element_id": 4, "title": "赤色山脊的铸星师", "color": Color("ffc39c"), "dark": Color("955955"), "skill": "赤岩印", "burst": "丹阙山阵", "weapon": "岩印", "description": "用红砂修复星屿的裂隙，为归来的人垒起新家。", "ability": "赤岩护盾与震地；岩柱阵连续震击四次。", "cooldown": 9.0, "banner": "山河有信", "tagline": "让破碎的地方，长出新的家园。"},
	{"name": "燎原", "element": "焰", "element_id": 1, "title": "追着晨光奔跑的人", "color": Color("ffd183"), "dark": Color("925337"), "skill": "逐日踏", "burst": "黎明之翼", "weapon": "日轮双刃", "description": "替村庄跑遍整座岛屿，亲手将重燃的火种送往远方。", "ability": "逐日突进获得更厚护盾；凤凰轰击与持续火场。", "cooldown": 8.0, "banner": "晨光万里", "tagline": "这一次，让整片原野都看见黎明。"}
]
const AFTERLIGHT_CHARACTERS = [
	{"name": "丝萝", "element": "风", "element_id": 0, "title": "为森林缝补晨光的人", "color": Color("b9dfac"), "dark": Color("496951"), "skill": "叶舞结", "burst": "森息回廊", "weapon": "叶刃", "description": "苔庭最后的织叶师，带着一只失去家园的萤灵寻找森林的心跳。", "ability": "飞叶环绕自身连续追击；风域安抚森林并治疗队伍。", "cooldown": 8.0, "banner": "林间拾梦", "tagline": "每一片新叶，都记得你带来的风。"},
	{"name": "珀砂", "element": "岩", "element_id": 4, "title": "记住年轮的刻匠", "color": Color("e9c09b"), "dark": Color("725b4c"), "skill": "年轮印", "burst": "山木同契", "weapon": "年轮锤", "description": "在树木与岩层之间寻找旧日约定，让沉默的大地重新开口。", "ability": "岩晶震地并获护盾；六柱岩阵持续共鸣。", "cooldown": 9.0, "banner": "年轮刻约", "tagline": "岩石也会生长，只是比树慢一些。"},
	{"name": "溟弦", "element": "潮", "element_id": 2, "title": "雾中归舟的琴师", "color": Color("9adce2"), "dark": Color("365e7a"), "skill": "弦潮贯", "burst": "沧浪和鸣", "weapon": "潮弦杖", "description": "循着林间泉水走来的琴师，听见了埋在旧钟里的另一段旋律。", "ability": "三段潮束贯穿前方并治疗；潮域聚敌持续恢复。", "cooldown": 8.0, "banner": "雾海听弦", "tagline": "你未说完的话，我替潮水记着。"},
	{"name": "昭璃", "element": "焰", "element_id": 1, "title": "守住第一声晨钟的人", "color": Color("ffd2a0"), "dark": Color("874b48"), "skill": "曦焰坠", "burst": "长昼之冠", "weapon": "曦光剑", "description": "晨钟遗址的年轻守望者，在钟声失落的年代独自点亮灯台。", "ability": "召来曦焰落星；爆发连续三轮日冕轰击。", "cooldown": 8.0, "banner": "长昼初鸣", "tagline": "晨光会来，我们先点灯。"},
	{"name": "夜弦", "element": "雷", "element_id": 3, "title": "听见星轨的调律师", "color": Color("bdb6f0"), "dark": Color("514969"), "skill": "惊弦链", "burst": "万籁惊雷", "weapon": "调律枪", "description": "替旧日钟塔校准星轨的调律师，终于学会倾听人的声音。", "ability": "五目标连锁留下雷印；三轮雷击引发印记共鸣。", "cooldown": 7.0, "banner": "夜尽回声", "tagline": "最后一个音，留给醒来的世界。"},
	{"name": "青羽", "element": "风", "element_id": 0, "title": "把明天写进长风的人", "color": Color("b7e7cf"), "dark": Color("416f6b"), "skill": "远羽环", "burst": "万里风书", "weapon": "羽剑", "description": "记录新旅途的年轻绘图师，画下重获心跳的森林与钟声。", "ability": "强化归航风轮；风域聚敌并为旅人持续治疗。", "cooldown": 7.0, "banner": "万里来风", "tagline": "地图的尽头，还有我们没见过的春天。"}
]
const CHARACTER_COUNT = 23
const LIMITED_IDS = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22]
const BANNER_BATCHES = [[5, 6, 7], [8, 9, 10], [11, 12, 13], [14, 15, 16], [17, 18, 19], [20, 21, 22]]
const BATCH_NAMES = ["初遇星海", "沉潮来信", "群星归航", "黎明新旅", "森心苏醒", "晨钟之约"]
const LAST_QUEST = 34
const CHEST_COINS = 30
const LIMITED_SKILLS = {
	5: ["投出一枚月轮，向目标飞行后回到身边。去程与归程各命中一次；归返恢复 12 生命。冷却 7 秒。", "在身边展开持续 8 秒的风域，每 2 秒造成一次范围风伤并聚拢普通敌人。站在风域中，每次脉冲恢复 8 生命，共 4 次。"],
	6: ["向目标方向突进约 9 米，沿途造成焰伤并留下羽状火光。获得 25 点护盾和短暂受击保护；碰到墙壁会停下。冷却 8 秒。", "召来火凤凰，1 秒后俯冲轰击目标区域。命中后留下火场，随后造成 4 次灼烧脉冲。适合用突进拉近距离后释放。"],
	7: ["雷光依次连锁至多 4 个敌人，目标间距离不超过 9 米。每个目标留下持续 8 秒的雷印，并获得短暂受击保护。冷却 7 秒。", "在目标区域布下星环，预警后降下 3 轮落雷。带雷印的目标每轮受到额外伤害。先用 E 留下雷印，再用 Q 引爆连携。"]
}

static func character(index: int) -> Dictionary:
	if index >= 17:
		return AFTERLIGHT_CHARACTERS[index - 17]
	if index < 5:
		return CHARACTERS[index]
	return LIMITED_CHARACTERS[index - 5] if index < 8 else CHAPTER_CHARACTERS[index - 8]

static func element_of(index: int) -> int:
	return index if index < 5 else int(character(index)["element_id"])

static func rotation_for_quest(stage: int) -> int:
	if stage >= 19:
		return 5 if stage >= 24 else 4
	return 3 if stage >= 14 else (2 if stage >= 9 else (1 if stage >= 4 else 0))

static func banner_ids(stage: int) -> Array:
	return BANNER_BATCHES[rotation_for_quest(stage)]

static func batch_of(index: int) -> int:
	return (index - 5) / 3

static func skill_details(index: int) -> Array:
	if index == 17:
		return ["飞叶环绕自身 6 秒，每 1.5 秒造成一次半径 6 米的风伤，共 4 次。切换角色后仍跟随玩家。冷却 8 秒。", "在身边展开八秒风域，聚拢普通敌人，四次风伤脉冲。站在域内每次恢复 8 生命。"]
	if index == 19:
		return ["朝目标方向发出三段潮束，贯穿前方 18 米的敌人。每段恢复 6 生命，无目标也可治疗。冷却 8 秒。", "目标处生成八秒潮汐漩涡，每两秒牵引普通敌人并造成潮伤；站在潮域内每次恢复 10 生命。"]
	if index == 20:
		return ["在前方唤来曦焰落星，一秒预警后轰击半径 7 米的敌人。冷却 8 秒。", "展开日冕法阵，一秒预警后连续三轮落星，对半径 11 米内的敌人造成焰伤。"]
	if index == 21:
		return [LIMITED_SKILLS[7][0].replace("4 个", "5 个"), LIMITED_SKILLS[7][1]]
	if LIMITED_SKILLS.has(index):
		return LIMITED_SKILLS[index]
	match element_of(index):
		0:
			return ["投出往返风轮，去程与归程各命中一次。%s冷却 7 秒。" % ("风刃伤害更高，归返恢复 6 生命。" if index == 12 else "归返恢复 12 生命。"), "展开%s风域，每 2 秒造成范围风伤、聚拢普通敌人。站在风域内每次恢复 8 生命。" % ("半径 13 米、持续 10 秒的五次脉冲" if index == 14 else "持续 8 秒的四次脉冲")]
		1:
			return ["向目标方向突进，沿途造成焰伤与羽状火光，获得 %d 护盾；碰到墙壁停下。冷却 8 秒。" % (40 if index == 16 else 25), "召来凤凰，1 秒预警后俯冲轰击区域，再造成 4 次火场灼烧。%s" % ("烬翎的俯冲伤害更高。" if index == 10 else "火场持续到释放后第 5.5 秒。")]
		2:
			return ["召唤三枚水珠，依次追击 18 米内的敌人，每次命中造成潮伤。每次释放水珠恢复 %d 生命，无目标也能治疗。冷却 8 秒。" % (12 if index == 11 else 8), "在目标处展开 8 秒漩涡，每 2 秒造成一次潮伤并牵引普通敌人，共 4 次。站在半径 10 米的潮域内，每次恢复 10 生命。"]
		3:
			return [LIMITED_SKILLS[7][0], "目标星环预警后落下 3 轮强化雷击。带雷印的敌人每轮受到额外伤害；先 E 再 Q 可触发连携。"]
		_:
			return ["获得 55 点护盾，在身边震起六枚岩晶，对半径 7 米的敌人造成岩伤。冷却 9 秒。", "在目标处升起六座岩柱，预警后共鸣震击 %d 次，每次造成岩伤。在半径 10 米的阵中，每次获得 10 点护盾；岩柱不阻挡移动。" % (4 if index == 15 else 3)]

static func character_color(index: int) -> Color:
	return character(index)["color"]

const SHRINES = [
	{"name": "长风丘陵", "subtitle": "风经过的地方，故事便有了方向。", "element": 0, "xz": Vector2(-53, 34), "memory": "风之残响：天空碎裂那天，有人把最后一封信托付给了风。"},
	{"name": "烬花原野", "subtitle": "灰烬之下，仍有未熄的星火。", "element": 1, "xz": Vector2(61, 27), "memory": "焰之残响：炉火并非为了战争而燃。它也曾照亮每一个归家的人。"},
	{"name": "镜潮湖畔", "subtitle": "潮水记得一切未曾说出口的名字。", "element": 2, "xz": Vector2(-67, -27), "memory": "潮之残响：旧城沉入海底之前，歌者们唱的是同一首关于黎明的歌。"},
	{"name": "鸣雷高地", "subtitle": "在风暴的间隙，听见天空的心跳。", "element": 3, "xz": Vector2(59, -49), "memory": "雷之残响：观星者发现，灾变不是神罚，而是守卫失控的保护机制。"},
	{"name": "磐古遗庭", "subtitle": "岁月会流逝，山的承诺不会。", "element": 4, "xz": Vector2(-30, -76), "memory": "岩之残响：五枚星核原本属于同一道光。唯有再次共鸣，才能唤醒守卫的心。"}
]

static func element_color(index: int) -> Color:
	return CHARACTERS[clampi(index, 0, 4)]["color"]

static func reaction(a: int, b: int) -> String:
	if a < 0 or a == b:
		return ""
	if a == 0 or b == 0:
		return "扩散"
	if a == 4 or b == 4:
		return "结晶"
	if (a == 1 and b == 2) or (a == 2 and b == 1):
		return "蒸腾"
	if (a == 2 and b == 3) or (a == 3 and b == 2):
		return "感电"
	return "超载"
