% function histogram_diffusion

    clear
    clc
    
    %% Inputs

    filename_input = 'IMG_3119.JPG';
    sample_spacing = 1; % px, to skip for downsampling; e.g. value of 3 samples every 3rd pixel
    diff_runtime = 200 * [1 1 1]; % s, duration for each color channel
    show_anim     = 1;
    export_result = 1;
    
    sat_thresh = 0.10; % percent of max
    space = 'RGB'; % 'RGB' or 'HSV'
    
    % Display properties
    fps = 15;
    duration_freeze = 1;
    duration_anim = 2;
    lw = 1.5; % line width
    
    %% Generate export filenames
    
    if show_anim && sample_spacing>=4
        res = fps * duration_anim;
    else
        res = 1;
    end
    
    str_runtime = '';
    for i = 1:length(diff_runtime)
        str_runtime = [str_runtime num2str(diff_runtime(i)) '_'];
    end
    str_runtime = str_runtime(1:end-1);
    
    name = regexp(filename_input,'(.+)\.','tokens');
    name = name{1}{1};
    
    extension = regexp(filename_input,'\.(.+)','tokens');
    extension = extension{1}{1};
    
    filename_output_imag = [name '_runtime_' str_runtime '_sat-thresh-prcnt_' num2str(round(sat_thresh*100)) '_sample-spacing_' num2str(sample_spacing) '.' extension];
    filename_output_anim = regexprep(filename_output_imag,'\..+','.GIF');
    
    %% Initialize image
    
    I = imread(filename_input);
    I_ = I(1:sample_spacing:size(I,1),1:sample_spacing:size(I,2),:);
    
    switch space
        case 'RGB'
            % Do nothing - image is already in RGB
        case 'HSV'
            I_ = rgb2hsv(I_);
        otherwise
            error('Unrecognized color space')
    end
    
    %% Add random noise for exact histogram matching
    
%     I_ = I_ + rand(size(I_))/1000 - 1/2000;
%     
%     I_(I_>1) = 1;
%     I_(I_<0) = 0;
    
    %% Generate histograms
    
    edges = -0.5 : 255.5;
    for cc = 1:3
        [y, ~] = histcounts(I_(:,:,cc), edges);
        
        Hist.orig(cc,:) = y;
    end
    
    %% Main body
    
    % Initialize
    Hist.diff = Hist.orig;
    
    figure(1)
    pos = get(gcf,'position');
    set(gcf,'position',[pos(1:2) 650 650])
    
    % Initialize as equal
    Hist.post = Hist.orig;
    J = I_;
    
    for d = 0:res
        
        if d > 0 % supress calculation for first loop, to show initial state
    
            % Diffuse histograms
            dt = 0.05; % s
            for cc = 1:3
                Hist.diff(cc,:) = diffuse(Hist.diff(cc,:),dt,diff_runtime(cc)/res,sat_thresh);
                Hist.diff(cc,:) = Hist.diff(cc,:) / sum(Hist.diff(cc,:)) * sum(Hist.orig(cc,:));
            end

            % Apply histogram equalization
            J = zeros(size(I_));
            for cc = 1:3
                if diff_runtime(cc) > 0
    %                 J(:,:,cc) = histeq         (I_(:,:,cc), Hist.diff(cc,:));
                    J(:,:,cc) = exact_histogram(I_(:,:,cc), Hist.diff(cc,:));
                else
                    J(:,:,cc) = I_(:,:,cc);
                end
            end

            % Calculate resulting histogram
            for cc = 1:3
                [y, ~] = histcounts(J(:,:,cc), edges);
                Hist.post(cc,:) = y;
            end
        
        end

        % Convert back to RGB for display
        switch space
            case 'RGB'
                % Do nothing
            case 'HSV'
                I_ = hsv2rgb(I_);
                J  = hsv2rgb(J);
            otherwise
                error('Unrecognized color space')
        end

        % Show results
        x = linspace(0,1,256);
        hh = 0.15; % histogram height, normalized
        hWL = 0.75; % histogram water line (WL), height within figure
        fs = 8; % font size

        figure(1)

            clf
            hold on
            set(gcf,'color','white')

            for cc = 1:3
                subplot(2,3,cc)
                set(gca,'fontsize',fs)
                pos = get(gca,'position');
                pos(4) = hh;
                pos(2) = hWL;
                set(gca,'position',pos)
                hold on
                plot(x,Hist.orig(cc,:),'Color',zeros(1,3)+0.4,'LineWidth',lw)
                plot(x,Hist.diff(cc,:),'k',                   'LineWidth',lw)
                b = Hist.post(cc,:);
                bar(x,b,'FaceColor',0.75+zeros(1,3),'EdgeColor','none','BarWidth',0.5)
                grid on
                xlabel('Level, Normalized 0-1')
                if cc == 1
                    ylabel('Pixel Count')
                else
                    set(gca,'YTickLabel',[]);
                end

                switch space

                    case 'RGB'
                        switch cc
                            case 1
                                title('Red Channel')
                            case 2
                                title('Green Channel')
                            case 3
                                title('Blue Channel')
                        end
                    case 'HSV'
                        switch cc
                            case 1
                                title('Hue Channel')
                            case 2
                                title('Saturation Channel')
                            case 3
                                title('Value Channel')
                        end
                    otherwise
                        error('Unrecognized color space')

                end
                xlim([0 1])
                yl = max(Hist.orig(:,2:end-1));
                yl = max(yl);
                ylim([0 yl])
            end

    %         subplot(2,3,1)
    %         legend({'Raw','Diffused','Post'},'location','northwest')

            subplot(2,3,[4,5,6])
            pos = get(gca,'position');
            set(gca,'position',[pos(1:3) hWL-0.20])

            image(double(J)/255)
            axis equal
            axis tight
            axis off

            drawnow
            
            % Capture the plot as an image 
            frame = getframe(gcf); 
            im = frame2im(frame); 
            [imind,cm] = rgb2ind(im,256);
            if export_result
                if d == 0
                    imwrite(imind,cm,filename_output_anim,'gif', 'Loopcount',inf,'DelayTime',duration_freeze); 
                else 
                    imwrite(imind,cm,filename_output_anim,'gif','WriteMode','append','DelayTime',1/fps); 
                end
            end
            
    end
    
    % Capture the final frame
    frame = getframe(gcf); 
    im = frame2im(frame); 
    [imind,cm] = rgb2ind(im,256);
    if export_result
        imwrite(imind,cm,filename_output_anim,'gif','WriteMode','append','DelayTime',duration_freeze);
    end
    
%     figure(2)
%         clf
%         hold on
%         set(gcf,'color','white')
%         ax1 = subplot(1,2,1);
%         image(I_)
%         axis equal
%         axis tight
%         axis off
%         title('Original')
%         ax2 = subplot(1,2,2);
%         image(double(J)/256)
%         axis equal
%         axis tight
%         axis off
%         title('Diffused')
%         linkaxes([ax1 ax2],'xy')
%         drawnow

    % Prepare a comparison side-by-side image
    ind_split = round(size(J,2)/2);
    I_comp = I_;
    I_comp(:,ind_split:end,:) = J(:,ind_split:end,:);
        
    figure(3)
        clf
        hold on
        set(gcf,'color','white')
        image(flipud(I_comp))
        axis equal
        axis tight
        axis off
        
    %% Export results
    
    if export_result
        imwrite(double(I_comp)/256,regexprep(filename_output_imag,'\.','_comp.'))
        imwrite(double(J)/256,filename_output_imag) 
    end
    
% end


















































