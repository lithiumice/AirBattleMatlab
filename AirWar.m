function AirWar
clear all;
% ����ȫ�ֱ���
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

%��������
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
        mp3p = audioplayer(mp3Y,mp3Fs); % ���������ļ�
        play(mp3p); %��ʼ����

        mp3FileName = 'biu.mp3';
        [mp3Y,mp3Fs] = audioread(mp3FileName);
        biu = audioplayer(mp3Y,mp3Fs);

        mp3FileName = 'bomb1.mp3';
        [mp3Y,mp3Fs] = audioread(mp3FileName);
        bomb1 = audioplayer(mp3Y,mp3Fs);

        mp3FileName = 'bomb2.mp3';
        [mp3Y,mp3Fs] = audioread(mp3FileName);
        bomb2 = audioplayer(mp3Y,mp3Fs);

        % ��ʼ��
        ControlTimer = 0;
        score = 0;
        speed = 1.3;
        BulletList = [];
        PlaneOppList = [];

        % ImgData: x y 3 ά�ȵ���������; AlpData: x y ͸��������
        [Bkg.ImgData, ~, Bkg.AlpData] = imread('bkg2.jpg');
        [Bkg.SizeY, Bkg.SizeX, Bkg.ImDepth] = size(Bkg.ImgData);%SizeX: x����Ĵ�С
        
        [Line.ImgData, ~, Line.AlpData] = imread('line2.png');
        [Line.SizeY, Line.SizeX, Line.ImDepth] = size(Line.ImgData);
        
        [PlaneOwn.ImgData, ~, PlaneOwn.AlpData] = imread('planeown.png');
        [PlaneOwn.SizeY, PlaneOwn.SizeX, PlaneOwn.ImDepth] = size(PlaneOwn.ImgData);
        PlaneOwn.PosX = Bkg.SizeX/2 - PlaneOwn.SizeX/2;
        PlaneOwn.PosY = 40;
        
        for i=1:6 %����6���ӵ���ͼ��,�ļ���Ϊbullet1~6.png
            [temp_ImgData, ~, temp_AlpData]=imread(['bullet',num2str(i),'.png']);
            temp_size = size(temp_ImgData);
            % BulletΪ����6���ӵ�������
            Bullet.(['BulletType', num2str(i)]).ImgData = temp_ImgData;
            Bullet.(['BulletType', num2str(i)]).AlpData = temp_AlpData;
            Bullet.(['BulletType', num2str(i)]).SizeY = temp_size(1);
            Bullet.(['BulletType', num2str(i)]).SizeX = temp_size(2);
        end

        for i=1:3 %����3���л���ͼ��,�ļ���Ϊplaneopp1~6.png
            [tempopp_ImgData, ~, tempopp_AlpData]=imread(['planeopp',num2str(i),'.png']);
            tempopp_size = size(tempopp_ImgData);
            PlaneOpp.(['PlaneOppType', num2str(i)]).ImgData = tempopp_ImgData;
            PlaneOpp.(['PlaneOppType', num2str(i)]).AlpData = tempopp_AlpData;
            PlaneOpp.(['PlaneOppType', num2str(i)]).SizeY = tempopp_size(1);
            PlaneOpp.(['PlaneOppType', num2str(i)]).SizeX = tempopp_size(2);
        end

        % ������Ϸ���崰��,��СΪBkg.SizeX/1.2 Bkg.SizeY/1.2,�ര����ߺ�����ľ���ֱ�Ϊ550 100
        Mainfig=figure('units','pixels',...
                       'position',[550 100 Bkg.SizeX/1.2 Bkg.SizeY/1.2],...
                       'Numbertitle','off',...
                       'menubar','none',...
                       'resize','off',...
                       'name','air war');
        % ����������,ԭ�������½�
        Mainaxes=axes('parent',Mainfig,...
                      'position',[0 0 1 1],...
                      'XLim', [0 Bkg.SizeX],...
                      'YLim', [0 Bkg.SizeY],...
                      'NextPlot','add',...
                      'layer','bottom',...
                      'Visible','on',...
                      'XTick',[], ...
                      'YTick',[]);

        % ��ʾ����ͼ��
        DrawBkgHdl = image([0 Bkg.SizeX], [0 Bkg.SizeY], flipud(Bkg.ImgData));
        % ��ʾ��ɫ������, 0.5��͸����
        DrawLineHdl = image([0 Bkg.SizeX], [0 Line.SizeY] + 180, flipud(Line.ImgData), 'alphaData', flipud(Line.AlpData).*0.5);
        DrawPlaneOwnHdl = image([0 PlaneOwn.SizeX] + PlaneOwn.PosX, [0 PlaneOwn.SizeY] + PlaneOwn.PosY, flipud(PlaneOwn.ImgData),...
                                'alphaData',flipud(PlaneOwn.AlpData));
        % TempBkgΪ�������򱳾�ƴ��������ͼ��,�Ա���ʾ�����ı���ͼ��
        TempBkg = flipud([Bkg.ImgData;Bkg.ImgData]);
        % ������ʱ��,ÿ1/fps��ִ��һ��TimerFcn�ص�����
        Game = timer('ExecutionMode', 'FixedRate', 'Period', 1/fps, 'TimerFcn', @AirWarMain);
        % ���ô��ڹرյĻص�����,���ڴ��ڹر�ʱִ��CloseRequestFcn����
        set(gcf,'tag','MainTag','CloseRequestFcn',@CloseGame);
        % ��������
        set(gcf,'WindowButtonMotionFcn',@PlaneOwnMove);
        % ��������
        set(gcf,'WindowButtonDownFcn',@PlaneOwnShoot);
        % ��ʱ����ʼ��ʱ
        start(Game);
    end

    function  AirWarMain(~,~)
        % ��ControlTimer��������������߶�ʱ����
        if(ControlTimer >= Bkg.SizeY)
            ControlTimer = 0;
        else
            ControlTimer = ControlTimer + 1;
        end
        
        % ���������Ʊ���ͼ�������ƶ�
        set(DrawBkgHdl, 'CData', TempBkg(ControlTimer+1:ControlTimer+Bkg.SizeY, :, :));

        % ����speed�������һ���л�
        if(mod(ControlTimer, fps*speed) == 0)
            RandPlaneNum = randi([1 3]);
            RandPosX = randi(floor(Bkg.SizeX - PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).SizeX/2));
            TempNum = GetMax(PlaneOppList);
            DrawPlaneOppHdl(TempNum) = image([0 PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).SizeX] + RandPosX,...
                                             [0 PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).SizeY] + 750,...
                                            flipud(PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).ImgData),...
                                            'alphaData', flipud(PlaneOpp.(['PlaneOppType',num2str(RandPlaneNum)]).AlpData));   
            % ���µл���ӵ� PlaneOppListβ��                           
            PlaneOppList = [PlaneOppList; TempNum];
        end

        % ����ел����б���,�����ͼ��ʹ�л�����
        if ~isempty(PlaneOppList)
            for i = length(PlaneOppList) : -1 : 1
                TempNum =  PlaneOppList(i);
                TempY = get(DrawPlaneOppHdl(TempNum), 'YData');
                set(DrawPlaneOppHdl(TempNum), 'YData', TempY - 1.5);
            end
        end

        %�ж��ӵ���л��Ƿ�����ײ
        flag = 0;
        % ����ѭ���ı�־,ÿ����һ�εл���Ҫ����ѭ��,
        % �������õ���ɾ���Ķ����ʹ���򱨴�(����һ��ѭ�����������ӵ���һ�ܵл�������ײ)
        if (~isempty(BulletList) && ~flag)
            for i = length(BulletList) : -1 : 1
                if(flag)
                    break;
                end
                
                % �����ӵ���ͼ��,ʹ��������
                TempNum =  BulletList(i);
                TempY = get(DrawBulletHdl(TempNum), 'YData');
                set(DrawBulletHdl(TempNum), 'YData', TempY + 4);

                if TempY(1) > Bkg.SizeY % �ӵ�����������Χ�����Ƴ�
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

                            % �ӵ��͵л������ص�
                            if(OppX(1) <= JudgePosX) &&...
                            (JudgePosX <= OppX(2)) &&...
                            (OppY(1) <= JudgePosY)&&...
                            (JudgePosY <= OppY(2))
                                % �����ӵ��͵л�
                                BulletList(BulletList == TempNum) = [];
                                delete(DrawBulletHdl(TempNum));
                                
                                PlaneOppList(PlaneOppList == TempNumOpp) = [];
                                delete(DrawPlaneOppHdl(TempNumOpp));

                                % ���ű�ը����
                                if(isplaying(bomb1))
                                    stop(bomb1);
                                end
                                play(bomb1);
                                score = score + 1;

                                % ���·���
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
        JudgeLose();%�жϵл�λ��
    end

    function PlaneOwnShoot(src,~)
        seltype = src.SelectionType;
        temp_num = GetMax(BulletList);
        if(isplaying(biu))
            stop(biu);
        end
        play(biu);
        switch (seltype)
            case 'normal' %����������
                DrawBulletHdl(temp_num) = image([0 Bullet.BulletType1.SizeX] + PlaneOwn.PosX + PlaneOwn.SizeX/2 - Bullet.BulletType1.SizeY/2,...
                                                [0 Bullet.BulletType1.SizeY] + PlaneOwn.PosY + PlaneOwn.SizeY, flipud(Bullet.BulletType1.ImgData),...
                                                'alphaData', flipud(Bullet.BulletType1.AlpData));   
            case 'extend' %����Ҽ�����
                DrawBulletHdl(temp_num) = image([0 Bullet.BulletType2.SizeX] + PlaneOwn.PosX + PlaneOwn.SizeX/2 - Bullet.BulletType2.SizeY/2,...
                                                    [0 Bullet.BulletType2.SizeY] + PlaneOwn.PosY + PlaneOwn.SizeY, flipud(Bullet.BulletType2.ImgData),...
                                                'alphaData', flipud(Bullet.BulletType2.AlpData));   
            case 'alt' %����м�����
                DrawBulletHdl(temp_num) = image([0 Bullet.BulletType3.SizeX] + PlaneOwn.PosX + PlaneOwn.SizeX/2 - Bullet.BulletType3.SizeY/2,...
                                                [0 Bullet.BulletType3.SizeY] + PlaneOwn.PosY + PlaneOwn.SizeY, flipud(Bullet.BulletType3.ImgData),...
                                                'alphaData', flipud(Bullet.BulletType3.AlpData));   
            case 'open' %���������
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
        delete(findobj('tag','MainTag'));%ɾ��������
        stop(mp3p);%�����˳����Ქ��
        clf,close;
    end

    function PlaneOwnMove(~,~)
        xy = get(gca,'CurrentPoint');%��ȡ�������,ֻ���������ڲ���Ч
        temp_x = xy(1,1); %temp_y=xy(1,2)
        PlaneOwn.PosX = temp_x - PlaneOwn.SizeX/2;%�ɻ�x�����������ͬ
        set(DrawPlaneOwnHdl,'XData', [0 PlaneOwn.SizeX] + PlaneOwn.PosX,...
                            'YData', [0 PlaneOwn.SizeY] + PlaneOwn.PosY); 
    end

    function JudgeLose(~,~)
        % ��һ�ܵл�y����С��180���ж�Ϊ��
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