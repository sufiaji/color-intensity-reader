function intensity_list = process_image(source_image,handle_of_checkbox,handle_of_axes)

% get handles of current axes
hax = handle_of_axes;
% 
% get handles of checkbox
hck = handle_of_checkbox;
% 
% remove previous rectangle object
r = findobj(hax,'type','rectangle');
delete(r);
t = findobj(hax,'type','text');
delete(t);

% the image to be processed
imgRead = source_image;
imshow(imgRead,'parent',hax);

% set initial value of intensity_list as an empty list
intensity_list = [];

% get the size of image (h = height, w = width)
h = size(imgRead,1);
w = size(imgRead,2);

% Get The Region of Interest (ROI)
% In this case, the chemical glass is our ROI
% To detect the top and bottom boundary of glass, first we divide image by 50% height.
% Let's say we get the upper part and lower part of image after getting
% divided by 50% of height
iUp = imgRead(1:ceil(h/2),:,:);
% iLo = imgRead(ceil(h/2):h,:,:);

% ---------------- PROCESSING OF UPPER PART IMAGE ----------------------
% We deal with the top boundary of chemical glass first ...
% Convert RGB to Gray Image, for upper part of image
iUpGray = rgb2gray(iUp);

% Perform edge detection of upper part image
% This operation returns a binary image, with 0 for background
% and 1 for the edges
uedge = edge(iUpGray,'prewitt',[],'horizontal');

% Remove small object to get noise-free egde image
uedge = bwareaopen(uedge,10,8);

% Perform morphological operation to make the blob area of edge, 
% those are erosion followed by dilation (morphologically open image).
% Erosion is intended to remove the unused branch in edge strips
% Dilation is intended to strengthen the edge strips
se1 = strel('line',5,0);
se2 = strel('line',50,90);
me = imerode(uedge,se1);
md = imdilate(me,se2);

% Again, remove noise object 
bwu = bwareaopen(md,50,8);
se3 = strel('line',10,0);

% Perform morphologically close image
bwu = imclose(bwu,se3);

% Get the horizontal profile of Blob Image
% We sum up all the pixel value of binary edge image per column (y),
% along in x coordinate
hzProfileUp = zeros(1,w);
for wi = 1:w
    usum = 0;
    for hi = 1:floor(h/2)
        usum = usum + bwu(hi,wi);
    end
    hzProfileUp(wi) = usum;
end
if(isempty(hzProfileUp))
    return; 
end
% Get the left-right coordinates of the boundary of chemical glass
index = 0;
centerGradCoords = zeros(1,1000);  
for lwi = 2:length(hzProfileUp)-1
    if((hzProfileUp(lwi)==0 && hzProfileUp(lwi+1)>0) || ...
            (hzProfileUp(lwi)>0 && hzProfileUp(lwi+1)==0))
        index = index + 1;
        centerGradCoords(index) = lwi;
    end
end
centerGradCoords = centerGradCoords(1:index);
if (isempty(centerGradCoords)) 
    return; 
end
gradCoords = zeros(1,length(centerGradCoords)+2);
gradCoords(2:index+1) = centerGradCoords(1:index);
gradCoords(1) = 1;
gradCoords(length(gradCoords)) = w;

% Construct array of glass images ..
% for both RGB and edge images
% We need to collect the edge image in order to get the top boundary of
% chemical glass objects later
imgCell = {};
imgCellEdge = {};
index = 0;
leg = length(gradCoords)-1;
legp2 = floor(leg/2);
ctopw = zeros(legp2,2);
for i=1:leg
    x1 = gradCoords(i);
    x2 = gradCoords(i+1);
    modus = mode(hzProfileUp(x1:x2));
    if(modus ~= 0)
        index = index+1;
        imgCell{index} = imgRead(:,x1:x2,:);
        imgCellEdge{index} = uedge(:,x1:x2);
        ctopw(index,:) = [x1 x2];
    end
end
if(isempty(imgCell))
    return;
end
if(isempty(imgCellEdge))
    return;
end

% Get the top boundary of the chemical glass based on edge detection image
% and store each final processed image in an array
imgCellTop = {};
ctoph = zeros(length(imgCellEdge),1);
for f = 1:length(imgCellEdge)
    imgEdge = imgCellEdge{f};
    sImage  = imgCell{f};
    s = sum(imgEdge,2);
    for i=1:length(s)
        if(s(i) > 0)
            break;
        end
    end
    sImageTop = sImage(i:h,:,:);
    imgCellTop{f} = sImageTop;
    ctoph(f) = i;
end
if(isempty(imgCellTop))
    return
end
% ---------------- PROCESSING OF LOWER PART IMAGE ----------------------
% perform edge detection on the lower part from final processed image
% above. Because we already have the ROI of image (the chemical glasses) so
% to find the bottom boundary is much simpler; i.e. no need to do the
% closing or opening morphological operation
finalImage = {};
cboth = zeros(length(imgCellTop),1);
indexf = 0;
for f = 1:length(imgCellTop)
    % this is the image of chemical glass which has ben cut on the top
    % boundary, as the result of previous operation
    theImage = imgCellTop{f};
    % get the height and width of image
    ht = size(theImage,1);
%     wt = size(theImage,2);
    % -------- devide image by 50% height ----------------
    % this is the upper part of chemical glass image
    sImageTop = theImage(1:(floor(ht/2)-1),:,:);
    % this is the lower part of chemical glass image
    bImage = theImage(floor(ht/2):ht,:,:);
    % ----- perform image processing to the lower part of chemical glass image
    % convert RGB to Gray
    bgImage = rgb2gray(bImage);
    % edge detection, returns binary edge image
    bEdge = edge(bgImage,'prewitt',[],'horizontal');    
    % remove noise objects
    bEdge = bwareaopen(bEdge,20,8);
    % Get the vertical profile of lower part edge image
    % We sum up all the pixel value of binary edge image per column (x),
    % along in y coordinate
    s = sum(bEdge,2);
    if(isempty(s))
        continue
    end
    % find the first non-zero, from top to bottom
    % the non-zero means the bottom boundary
    for i=1:length(s)
        if(s(i) > 0)
            break;
        end
    end
    % cut the lower part image, from top to the coordinate of first-found
    % of non-zero pixel
    if(i==length(s))
        continue
    end
    sImageBot = bImage(1:i,:,:);    
    if(isempty(sImageBot))
        continue
    end
    cboth(f) = ctoph(f)+(floor(ht/2)-1)+i;
    % combine upper part of RGB image with the lower, already cut RGB image
    % store in a new array
    tempImg =  [sImageTop;sImageBot];
    if(size(tempImg,1) < size(tempImg,2))
        continue
    end
    indexf = indexf+1;
    finalImage{indexf} = tempImg;
end
if(isempty(finalImage))
    return
end

le = length(finalImage);
flag = 0;
if(get(hck,'Value')==get(hck,'Max'))
    flag = 1;
end
indez = 0;
intensities = [];
for i=1:le
    wi = ctopw(i,2)-ctopw(i,1);
    hi = cboth(i)-ctoph(i);
    if(wi > 0 && hi > 0 && hi > wi)
        singleImage = finalImage{i};
        indez = indez + 1;
        % mean of red intensity
        intensities(indez,1) = mean(mean(singleImage(:,:,1)));
        % mean of green intensity
        intensities(indez,2) = mean(mean(singleImage(:,:,2)));
        % mean of blue intensity
        intensities(indez,3) = mean(mean(singleImage(:,:,3)));
        % mean of color intensity 
        intensities(indez,4) = mean(mean(rgb2gray(singleImage))); 
        if flag == 1
            rectangle('position',[ctopw(i,1),ctoph(i),wi,hi],'parent',hax);
            text(ctopw(i,1),ctoph(i),num2str(indez),'parent',hax,'BackgroundColor',[.7 .9 .7],'fontsize',10);
        end
    end
end

% return the intensity list
intensity_list = intensities;





