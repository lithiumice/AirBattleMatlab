function AirWar
clear all;
% 定义全局变量
global Game;
global Bkg;
global Line;
global PlaneOwn;

global PlaneOpp;
global PlaneOppList;

global BulletList;
global Bullet

global ControlTimer;

global Mainfig;
global Mainaxes;

global DrawBkgHdl;
global DrawLineHdl;
global DrawPlaneOwnHdl;
global DrawPlaneOppHdl;
global DrawBulletHdl;

%声音对象
global biu;
global bomb1;
global bomb2;
global mp3p;

global TempBkg; 
global score;
global speed;
fps = 50;  

init();

    function init()
        mp3FileName = 'thunder love.m4a';
        [mp3Y,mp3Fs] = audioread(mp3FileName);
        mp3p = audioplayer(mp3Y,mp3Fs); % 加载音乐文件
        play(mp3p); %开始播放

        mp3FileName = 'biu.mp3';
        [mp3Y,mp3Fs] = audioread(mp3FileName);
        biu = audioplayer(mp3Y,mp3Fs);

        mp3FileName = 'bomb1.mp3';
        [mp3Y,mp3Fs] = audioread(mp3FileName);
        bomb1 = audioplayer(mp3Y,mp3Fs);

        mp3FileName = 'bomb2.mp3';
        [mp3Y,mp3Fs] = audioread(mp3FileName);
        bomb2 = audioplayer(mp3Y,mp3Fs);

        % 初始化
        ControlTimer = 0;
        score = 0;
        speed = 1.3;
        BulletList = [];
        PlaneOppList = [];

        % ImgData: x y 3 维度的像素数据; AlpData: x y 透明度数据
        [Bkg.ImgData, ~, Bkg.AlpData] = imread('bkg2.jpg');
        [Bkg.SizeY, Bkg.SizeX, Bkg.ImDepth] = size(Bkg.ImgData);%SizeX: x方向的大小
        
        [Line.ImgData, ~, Line.AlpData] = imread('line2.png');
        [Line.SizeY, Line.SizeX, Line.ImDepth] = size(Line.ImgData);
        
        [PlaneOwn.ImgData, ~, PlaneOwn.AlpData] = imread('planeown.png');
        [PlaneOwn.SizeY, PlaneOwn.SizeX, PlaneOwn.ImDepth] = size(PlaneOwn.ImgData);
        PlaneOwn.PosX = Bkg.SizeX/2 - PlaneOwn.SizeX/2;
        PlaneOwn.PosY = 40;
        
        for i=1:6 %加载6张子弹的图像,文件名为bullet1~6.png
            [temp_ImgData, ~, temp_AlpData]=imread(['bullet',num2str(i),'.png']);
            temp_size = size(temp_ImgData);
            % Bullet为储存6组子弹的数组
            Bullet.(['BulletType', num2str(i)]).ImgData = temp_ImgData;
            Bullet.(['BulletType', num2str(i)]).AlpData = temp_AlpData;
            Bullet.(['BulletType', num2str(i)]).SizeY = temp_size(1);
            Bullet.(['BulletType', num2str(i)]).SizeX = temp_size(2);
        end

        for i=1:3 %加载3个敌机的图像,文件名为planeopp1~6.png
            [tempopp_ImgData, ~, tempopp_AlpData]=imread(['planeopp',num2str(i),'.png']);
            tempopp_size = size(tempopp_ImgData);
            PlaneOpp.(['PlaneOppType', num2str(i)]).ImgData = tempopp_ImgData;
            PlaneOpp.(['PlaneOppType', num2str(i)]).AlpData = tempopp_AlpData;
            PlaneOpp.(['PlaneOppType', num2str(i)]).SizeY = tempopp_size(1);
            PlaneOpp.(['PlaneOppType', num2str(i)]).SizeX = tempopp_size(2);
        end

        % 创建游戏主体窗口,大小为Bkg.SizeX/1.2 Bkg.SizeY/1.2,距窗口左边和下面的距离分别为550 100
        Mainfig=figure('units','pixels',...
                       'position',[550 100 Bkg.SizeX/1.2 Bkg.SizeY/1.2],...
                       'Numbertitle','off',...
                       'menubar','none',...
                       'resize','off',...
                       'name','air war');
        % 创建坐标轴,原点在左下角
        Mainaxes=axes('parent',Mainfig,...
                      'position',[0 0 1 1],...
                      'XLim', [0 Bkg.SizeX],...
                      'YLim', [0 Bkg.SizeY],...
                      'NextPlot','add',...
                      'layer','bottom',...
                      'Visible','on',...
                      'XTick',[], ...
                      'YTick',[]);

        % 显示背景图像
        DrawBkgHdl = image([0 Bkg.SizeX], [0 Bkg.SizeY], flipud(Bkg.ImgData));
        % 显示黄色警戒线, 0.5的透明度
        DrawLineHdl = image([0 Bkg.SizeX], [0 Line.SizeY] + 180, flipud(Line.ImgData), 'alphaData', flipud(Line.AlpData).*0.5);
        DrawPlaneOwnHdl = image([0 PlaneOwn.SizeX] + PlaneOwn.PosX, [0 PlaneOwn.SizeY] + PlaneOwn.PosY, flipud(PlaneOwn.ImgData),...
                                'alphaData',flipud(PlaneOwn.AlpData));
        % TempBkg为两个纵向背景拼接起来的图像,以便显示滚动的背景图像
        TempBkg = flipud([Bkg.ImgData;Bkg.ImgData]);
        % 创建定时器,每1/fps秒执行一次TimerFcn回调函数
        Game = timer('ExecutionMode', 'FixedRate', 'Period', 1/fps, 'TimerFcn', @AirWarMain);
        % 设置窗口关闭的回调函数,即在窗口关闭时执行CloseRequestFcn函数
        set(gcf,'tag','MainTag','CloseRequestFcn',@CloseGame);
        % 类似上面
        set(gcf,'WindowButtonMotionFcn',@PlaneOwnMove);
        % 类似上面
        set(gcf,'WindowButtonDownFcn',@PlaneOwnShoot);
        % 定时器开始计时
        start(Game);
    end

    function  AirWarMain(~,~)
        % 当ControlTimer计数器超过纵向高度时置零
        if(ControlTimer >= Bkg.SizeY)
            ControlTimer = 0;
        else
            ControlTimer = ControlTimer + 1;
        end
        
        % 计数器控制背景图像向下移动
        set(DrawBkgHdl, 'CData', TempBkg(ControlTimer+1:ControlTimer+Bkg.SizeY, :, :));

        % 经过speed秒就生成一个敌机
        if(mod(ControlTimer, fps*speed) == 0)
            RandPlaneNum = randi([1 3]);
            RandPosX = randi(floor(Bkg.SizeX - PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).SizeX/2));
            TempNum = GetMax(PlaneOppList);
            DrawPlaneOppHdl(TempNum) = image([0 PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).SizeX] + RandPosX,...
                                             [0 PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).SizeY] + 750,...
                                            flipud(PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).ImgData),...
                                            'alphaData', flipud(PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).AlpData));   
            % 将新敌机添加到 PlaneOppList尾部                           
            PlaneOppList = [PlaneOppList; TempNum];
        end

        % 如果有敌机在列表中,则更新图像使敌机下移
        if ~isempty(PlaneOppList)
            for i = length(PlaneOppList) : -1 : 1
                TempNum =  PlaneOppList(i);
                TempY = get(DrawPlaneOppHdl(TempNum), 'YData');
                set(DrawPlaneOppHdl(TempNum), 'YData', TempY - 1.5);
            end
        end

        %判断子弹与敌机是否发生碰撞
        flag = 0;
        % 跳出循环的标志,每销毁一次敌机就要跳出循环,
        % 否则引用到已删除的对象会使程序报错(比如一次循环里有两个子弹和一架敌机发生碰撞)
        if (~isempty(BulletList) && ~flag)
            for i = length(BulletList) : -1 : 1
                if(flag)
                    break;
                end
                
                % 更新子弹的图像,使其向上移
                TempNum =  BulletList(i);
                TempY = get(DrawBulletHdl(TempNum), 'YData');
                set(DrawBulletHdl(TempNum), 'YData', TempY + 4);

                if TempY(1) > Bkg.SizeY % 子弹超出背景范围则将其移除
                    BulletList(BulletList == TempNum) = [];
                    delete(DrawBulletHdl(TempNum));
                else
                    if (~isempty(PlaneOppList) && ~flag)
                        for j = length(PlaneOppList) : -1 : 1
                            TempNumOpp =  PlaneOppList(j);

                            JudgePosX = mean(get(DrawBulletHdl(TempNum),'XData'));
                            JudgePosY = mean(get(DrawBulletHdl(TempNum),'YData')) - 20;

                            OppX = get(DrawPlaneOppHdl(TempNumOpp), 'XData');
                            OppY = get(DrawPlaneOppHdl(TempNumOpp), 'YData');

                            % 子弹和敌机发生重叠
                            if(OppX(1) <= JudgePosX) &&...
                            (JudgePosX <= OppX(2)) &&...
                            (OppY(1) <= JudgePosY)&&...
                            (JudgePosY <= OppY(2))
                                % 销毁子弹和敌机
                                BulletList(BulletList == TempNum) = [];
                                delete(DrawBulletHdl(TempNum));
                                
                                PlaneOppList(PlaneOppList == TempNumOpp) = [];
                                delete(DrawPlaneOppHdl(TempNumOpp));

                                % 播放爆炸声音
                                if(isplaying(bomb1))
                                    stop(bomb1);
                                end
                                play(bomb1);
                                score = score + 1;

                                % 更新分数
                                if(mod(score, 10))
                                    if(speed >= 1)
                                        speed = speed - 0.1;
                                    else
                                        speed = 1;
                                    end
                                end

                                flag = 1;
                                break;
                            end
                        end
                    end
                end
            end
        end
        JudgeLose();%判断敌机位置
    end

    function PlaneOwnShoot(src,~)
        seltype = src.SelectionType;
        temp_num = GetMax(BulletList);
        if(isplaying(biu))
            stop(biu);
        end
        play(biu);
        switch (seltype)
            case 'normal' %鼠标左键单击
                DrawBulletHdl(temp_num) = image([0 Bullet.BulletType1.SizeX] + PlaneOwn.PosX + PlaneOwn.SizeX/2 - Bullet.BulletType1.SizeY/2,...
                                                [0 Bullet.BulletType1.SizeY] + PlaneOwn.PosY + PlaneOwn.SizeY, flipud(Bullet.BulletType1.ImgData),...
                                                'alphaData', flipud(Bullet.BulletType1.AlpData));   
            case 'extend' %鼠标右键单击
                DrawBulletHdl(temp_num) = image([0 Bullet.BulletType2.SizeX] + PlaneOwn.PosX + PlaneOwn.SizeX/2 - Bullet.BulletType2.SizeY/2,...
                                                    [0 Bullet.BulletType2.SizeY] + PlaneOwn.PosY + PlaneOwn.SizeY, flipud(Bullet.BulletType2.ImgData),...
                                                'alphaData', flipud(Bullet.BulletType2.AlpData));   
            case 'alt' %鼠标中键单击
                DrawBulletHdl(temp_num) = image([0 Bullet.BulletType3.SizeX] + PlaneOwn.PosX + PlaneOwn.SizeX/2 - Bullet.BulletType3.SizeY/2,...
                                                [0 Bullet.BulletType3.SizeY] + PlaneOwn.PosY + PlaneOwn.SizeY, flipud(Bullet.BulletType3.ImgData),...
                                                'alphaData', flipud(Bullet.BulletType3.AlpData));   
            case 'open' %任意键单击
                DrawBulletHdl(temp_num) = image([0 Bullet.BulletType4.SizeX] + PlaneOwn.PosX + PlaneOwn.SizeX/2 - Bullet.BulletType4.SizeY/2,...
                                                [0 Bullet.BulletType4.SizeY] + PlaneOwn.PosY + PlaneOwn.SizeY, flipud(Bullet.BulletType4.ImgData),...
                                                'alphaData', flipud(Bullet.BulletType4.AlpData));   
            otherwise
            DrawBulletHdl(temp_num) = image([0 Bullet.BulletType5.SizeX] + PlaneOwn.PosX + PlaneOwn.SizeX/2 - Bullet.BulletType5.SizeY/2,...
                                                [0 Bullet.BulletType5.SizeY] + PlaneOwn.PosY + PlaneOwn.SizeY, flipud(Bullet.BulletType5.ImgData),...
                                                'alphaData', flipud(Bullet.BulletType5.AlpData));   
        end
        BulletList = [BulletList; temp_num];
    end

    function CloseGame(~,~)
        stop(Game);
        delete(findobj('tag','MainTag'));%删除主窗口
        stop(mp3p);%否则退出还会播放
        clf,close;
    end

    function PlaneOwnMove(~,~)
        xy = get(gca,'CurrentPoint');%获取鼠标坐标,只有在主窗口才有效
        temp_x = xy(1,1); %temp_y=xy(1,2)
        PlaneOwn.PosX = temp_x - PlaneOwn.SizeX/2;%飞机x坐标和鼠标的相同
        set(DrawPlaneOwnHdl,'XData', [0 PlaneOwn.SizeX] + PlaneOwn.PosX,...
                            'YData', [0 PlaneOwn.SizeY] + PlaneOwn.PosY); 
    end

    function JudgeLose(~,~)
        % 有一架敌机y坐标小于180则判定为输
        if ~isempty(PlaneOppList)
            for i = length(PlaneOppList) : -1 : 1
                TempNum =  PlaneOppList(i);
                TempY = min(get(DrawPlaneOppHdl(TempNum), 'YData'));
                if TempY <= 180
                    stop(Game)
                    set(gcf,'WindowButtonMotionFcn',[])
                    set(gcf,'WindowButtonDownFcn',[])
                    buttonName=questdlg('You lose. What do you mean to do?','You lose','close','restart','close');
                    switch buttonName
                        case 'restart',delete(gcf),init()
                        case 'close',delete(gcf)
                    end
                end
            end
        end
    end

    function num = GetMax(list)
        if isempty(list)
            num = 1;
        else
            num = max(list)+1;
        end
        
    end
end