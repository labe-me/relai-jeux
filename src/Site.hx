class Studio {
    public var name : String;
    public var url : String;
    public var games : Array<Game>;

    public function new(xml){
        var x = new haxe.xml.Fast(xml);
        name = x.att.name;
        url = x.att.url;
        games = [
            for (g in x.nodes.game)
                new Game(this, g)
        ];
    }
}

class Game {
    public var studio : Studio;
    public var name : String;
    public var url : String;
    public var desc : String;
    public var platforms : Array<GamePlatform>;
    public var videos : Array<String>;

    public function new(aStudio, x:haxe.xml.Fast){
        studio = aStudio;
        name = x.att.name;
        url = x.att.url;
        desc = StringTools.htmlEscape(x.node.desc.innerHTML.substr(0, 200));
        platforms = [
            for (p in x.nodes.platform)
                new GamePlatform(this, p)
        ];
        videos = [
            for (v in x.nodes.video)
                v.att.url
        ];
    }
}

enum Platform {
    WEB;
    IOS;
    ANDROID;
    OSX;
    WINDOWS;
    LINUX;
    XBOX360;
    XBOX720;
    PSP;
    PSVITA;
    PS2;
    PS3;
    PS4;
    WII;
    WII_U;
    DS;
    _3DS;
}

enum Requirement {
    LEAP;
    NEUROSKY;
    PSMOVE;
    KINECT;
}

class GamePlatform {
    public var game : Game;
    public var date : String;
    public var type : Platform;
    public var url : String;

    public function new(aGame, x:haxe.xml.Fast){
        game = aGame;
        type = Tool.stringToPlatform(x.att.type);
        date = x.att.date;
        url = x.att.url;
    }
}

class Tool {
    public static function stringToPlatform(str:String){
        var str = str.toUpperCase();
        if (str.charAt(0) >= "0" && str.charAt(0) <= "9")
            str = "_"+str;
        return Type.createEnum(Platform, str, []);
    }

    public static function platformToString(p:Platform){
        var str = Std.string(p);
        str = StringTools.replace(str, "_", "");
        return str;
    }
}

class Site {
    static var studios = new Array<Studio>();

    static function loadData(){
        for (studioDir in sys.FileSystem.readDirectory("data")){
            if (studioDir.charAt(0) == ".")
                continue;
            loadStudio('data/${studioDir}', studioDir);
        }
    }

    static function loadStudio(path, key){
        trace('Loading studio ${path} ${key}');
        var src = sys.io.File.getContent('${path}/index.xml');
        var xml = Xml.parse(src);
        studios.push(new Studio(xml.firstElement()));
    }

    static function build(template:haxe.Template, out, params){
        trace('Building template ${out}');
        var output = template.execute(params);
        sys.io.File.saveContent(out, output);
    }

    static function loadTemplate(path) : haxe.Template {
        return new haxe.Template(sys.io.File.getContent(path));
    }

    static function fetchNewsByDay(){
        var days = new Map<String, { date:String, news:List<{ studio:Studio, game:Game, platforms:Array<GamePlatform> }> }>();
        for (studio in studios){
            for (game in studio.games){
                for (platform in game.platforms){
                    var day = days.get(platform.date);
                    if (day == null){
                        day = {
                            date:platform.date,
                            news:new List()
                        }
                        days.set(platform.date, day);
                    }
                    var done = false;
                    for (n in day.news){
                        if (n.game == game){
                            n.platforms.push(platform);
                            done = true;
                            break;
                        }
                    }
                    if (!done){
                        day.news.push({
                            studio:studio,
                            game:game,
                            platforms:[platform]
                        });
                    }
                }
            }
        }
        var array = Lambda.array(days);
        array.sort(function(a,b){
            return -Reflect.compare(a.date, b.date);
        });
        return array;
    }

    public static function main(){
        loadData();
        build(loadTemplate("src/index.mtt"), "index.html", {
            days: fetchNewsByDay()
        });
    }
}