%This script shows the torque generation of a permanent magnet DC motor
%since the current running through conductor loops depend on the resistance
%and impedance of the electrical curcuit as well as counter electromotor
%force generated by DC motor, taken as fixed parameter which can be change 
%changing parameter (I) below.

%length of the conductor loop travelling in magnetic field is (l),
%width of the conductor loop travelling in magnetic field is (w).

%rotational velocity of armature (parameter (om)) is also fixed, since it's depended on
%angular momentum of the armature and existing resistance
global NC
global NP
global l
global w
global g0
global d
global I
global om
global phi
global Br
global Mo
global beta
global ZP
global PosP
global Lp



NC  =    12;       %number of conductor loops
NP  =     8;       %number of magnets/poles

l   =   0.1;       %m length of a conductor loop
w   =  0.01;       %m width of a conductor loop
g0  = 0.001;       %m gap between magnets and conductor loops where it is thw lowest
d   =  0.01;       %m thickness of block magnets
 

I   =    30;       %A passing current
om  =  pi*2;       %rad/s wanted
phi = pi/NC;       %phase shift between conductor loops

Br  =  1.08;       %tesla residual magnetism of N30 grade NdFeB permanent magnet
Mo  = 4*pi*10^-7;  %H magnetic permeability of free space   

ts  =   0.5;       %total time of simulation
t   = 0:0.01:ts;   %time matrix 

beta= pi*(NP-2)/NP;          %angle between each magnet placed 
Lp  = (w+2*g0)*cot(beta/2);  %length of each magnet's surface

PosP=zeros(NP, 2); %matrix to calculate middle points of magnet edges
for j = 0:NP-1
    PosP(j+1,1) = (w/2+g0)*cos(pi+(j*2*pi/NP)); %calculating Xj of the magnets
    PosP(j+1,2) = (w/2+g0)*sin(pi+(j*2*pi/NP)); %calculating Yj of the magnets
end

ZP=zeros(NP, 2); %matrix to calculate magnetic zones
for j = 0:NP-1
    ZP(j+1,1) = mod(pi/2 + beta/2 + j * (pi - beta), 2*pi); %beginning of the magnets zone
    ZP(j+1,2) = mod(pi/2 + beta/2 + (j+1)*(pi-beta), 2*pi); %ending of the magnets zone
end


s = size(t);
%Force genareted in each loop is F = B*i*l*sinQ
%torque genareted is T = F/w
F = zeros(1, s(1, 2));
T = zeros(1, s(1, 2));
for i = 1:s(1, 2)
    for j = 1:2*NC
        %it's assumed that every loop has current running at the moment
        %mathematical it corresponds to sum of force generated by
        %magnetical field B on each conductor loop that current I passing
        %equally at the time t. It's also assumed that each conductor is
        %placed uniformally within the same center position O with angular
        %difference pi/number of conductor loops.
        
        F(1, i) = F(1, i) + FC(j, t(1,i)) + FM(j, t(1,i));
    end
    T(1, i) = F(1, i)*w;
end


figure;
subplot(2,1,1)
plot(t,F)
title('Force(N) in time(s)')

subplot(2,1,2)
plot(t,T)
title('Torque(Nm) in time(s)')

%to show magnetic flux density heatmap
%figure;
%{
mapX = (-(g0 + (w/2))):0.0001:(g0 + w/2); %X axis of the heatmap
mapY = (-(g0 + (w/2))):0.0001:(g0 + w/2); %Y axis of the heatmap
smap = size(mapX);
BRot = zeros(smap(1,2),smap(1,2));
for i = 1:s(1, 2)
    for x = 1:smap(1,2)
        XVal = mapX(1, x);
        for y = 1:smap(1,2)
            YVal = mapY(1, y);
            if((XVal^2 + YVal^2) <= (g0 + w/2 +d)^2) 
                %to easily seriliaze only the points fall in the tangent
                %circle of middle points of pole edges taken in the count
                %depending on the graph you would like to see
                %please uncomment the one you desire and comment others
               
                %Magnetic field rotating arround origin
                %BRot(y, x) = BPR(XVal, YVal) + BCR (XVal, YVal, t(1,i));
                
                %Magnetic field away/towards to origin
                %BRot(y, x) = BPA(XVal, YVal) + BCA (XVal, YVal, t(1 ,i));
                
                %Scalar amplitude of magnetic field
                BRot(y, x) = sqrt((BPR(XVal, YVal) + BCR (XVal, YVal, t(1 ,i)))^2 + (BPA(XVal, YVal) + BCA (XVal, YVal, t(1 ,i)))^2);
            else
                BRot(y, x) = 0;
            end
        end
    end
    figure;
    h = heatmap(mapX,mapY,BRot, 'ColorMap', jet);
    str = 'Amplitude of Magnetic Field at ';
    h.Title = sprintf('%s_%d',str,t(1,i));
    %pause(0.0005);
    %saveas(h,sprintf('FIG%d.png',i)); % will create FIG1, FIG2,...
end
%}



%A function to find position of a half condutor loop j,
%travelling with angular velocity om 
%in the moment m_t
function [Xj, Yj] = PosC(j, m_t)
global w
global om
global phi
    Xj = (w/2)*cos(pi + om*m_t + (j - 1)*phi);
    Yj = (w/2)*sin(pi + om*m_t + (j - 1)*phi);
end

%A function to find pole of each magnet j
function PPj = PP(j)
    if(mod(j, 2) == 1)
        PPj =  1;
    else
        PPj = -1;
    end
end

%A function to find polarity of each half conductor loop k
%at the moment m_t
function PCj = PC(k, m_t)
global om
global phi
global NP
global ZP

    polarity = 0;
    ang_pos = mod(pi + om*m_t + (k-1)*phi, 2*pi); %angular position of the corresponding conductor loop
    l = 1;
    while(l <= NP)
        if(ZP(l,1) <= ang_pos && ang_pos < ZP(l,2))
            polarity = 1/PP(l);
            break;
        end
        l = l + 1;
    end
    PCj = polarity;
end

%A function to calculate total force applied on half of a conductor loop j
%by the magnetic field created by other half of conductor loops k
%at the moment m_t
function FCj = FC(j, m_t)
global NC
global phi
global l
global I
global Mo
    F = 0;
    [Xj, Yj] = PosC(j, m_t);
    for k = 1:2*NC
        if(k ~= j)
            [Xk, Yk] = PosC(k, m_t);
            F = F + sin((pi-(k-j)*phi)/2)*(PC(j,m_t)*PC(k,m_t)*l*I^2*Mo)/(2*pi*sqrt((Xj-Xk)^2 + (Yj-Yk)^2));
        end
    end
    FCj = F;
end

%A function to calculate total force applied on half of a conductor loop j
%by the magnetic field created by permanent magnets in direction of
%rotation at the moment m_t
function FMj = FM(j, m_t)
global NP
global om
global phi
global l
global I
global PosP
global Br
global Lp
global d
    F = 0;
    [Xj, Yj] = PosC(j, m_t);
    m1 = tan(pi/2 + om * m_t + (j-1) * phi); %slope of perpendicular plane to angular velocity
    for k = 1:NP
        Xk= PosP(k , 1);
        Yk= PosP(k , 2);
        m2 = (Yk-Yj)/(Xk-Xj); %slope of vectoral magnetic field 
        theta = atan((m1 - m2)/(1 + m1*m2)); %angle between magnetic field vector and perpendicular plane
        Z = sqrt((Xk-Xj)^2+(Yk-Yj)^2);
        var = I*l*PP(k)*PP(j)*cos(theta)*(Br/pi);
        geo1= l*Lp/(2*(Z)*sqrt(4*(Z^2)+Lp^2+l^2));
        geo2= l*Lp/(2*(d+Z)*sqrt(4*((Z+d)^2)+Lp^2+l^2));
        F = F + var * (atan(geo1) - atan(geo2));
    end
    FMj = F;
end

%A function to calculate total magnetic flux density applied on a point
%by permanent magnets, assuming that object is rotating arround origin
%or magnetic flux density rotating around origin
function BPRP = BPR(X, Y)
global NP
global l
global PosP
global Br
global Lp
global d
    B  = 0;
    m1 = -1/(Y / X); %slope of perpendicular plane to line to origin
    for k = 1:NP
        Xk= PosP(k , 1);
        Yk= PosP(k , 2);
        m2 = (Yk-Y)/(Xk-X); %slope of vectoral magnetic field 
        theta = atan((m1 - m2)/(1 + m1*m2)); %angle between magnetic field vector and perpendicular plane
        Z = sqrt((Xk-X)^2+(Yk-Y)^2);
        var = PP(k)*cos(theta)*(Br/pi);
        geo1= l*Lp/(2*(Z)*sqrt(4*(Z^2)+Lp^2+l^2));
        geo2= l*Lp/(2*(d+Z)*sqrt(4*((Z+d)^2)+Lp^2+l^2));
        B = B + var * (atan(geo1) - atan(geo2));
    end
    BPRP = B;
end

%A function to calculate total magnetic flux density applied on a point
%by permanent magnets, assuming that object is moving away from origin
%or magnetic flux density on the direction of origin
function BPAP = BPA(X, Y)
global NP
global l
global PosP
global Br
global Lp
global d
    B  = 0;
    m1 = (Y / X); %slope of perpendicular plane to line to origin
    for k = 1:NP
        Xk= PosP(k , 1);
        Yk= PosP(k , 2);
        m2 = (Yk-Y)/(Xk-X); %slope of vectoral magnetic field 
        theta = atan((m1 - m2)/(1 + m1*m2)); %angle between magnetic field vector and perpendicular plane
        Z = sqrt((Xk-X)^2+(Yk-Y)^2);
        var = PP(k)*cos(theta)*(Br/pi);
        geo1= l*Lp/(2*(Z)*sqrt(4*(Z^2)+Lp^2+l^2));
        geo2= l*Lp/(2*(d+Z)*sqrt(4*((Z+d)^2)+Lp^2+l^2));
        B = B + var * (atan(geo1) - atan(geo2));
    end
    BPAP = B;
end

%A function to calculate total magnetic flux density applied on a point
%by each half of conductor loops k, assuming that object is rotating arround origin
%or magnetic flux density rotating around origin
%at the moment m_t
function BCRP = BCR(X, Y, m_t)
global NC
global I
global Mo
    B  = 0;
    m1 =-1/(Y / X); %slope of perpendicular plane to line to origin
    for k = 1:2*NC
        [Xk, Yk] = PosC(k, m_t);
        m2 = (Yk-Y)/(Xk-X); %slope of vectoral magnetic field 
        theta = atan((m1 - m2)/(1 + m1*m2));
        B = B + cos(theta)*(PC(k,m_t)*I*Mo)/(2*pi*sqrt((X-Xk)^2 + (Y-Yk)^2));
    end
    BCRP = B;
end

%A function to calculate total magnetic flux density applied on a point
%by each half of conductor loops k, assuming that object is moving away from origin
%or magnetic flux density on the direction of origin
%at the moment m_t
function BCAP = BCA(X, Y, m_t)
global NC
global I
global Mo
    B  = 0;
    m1 = (Y / X); %slope of perpendicular plane to line to origin
    for k = 1:2*NC
        [Xk, Yk] = PosC(k, m_t);
        m2 = (Yk-Y)/(Xk-X); %slope of vectoral magnetic field 
        theta = atan((m1 - m2)/(1 + m1*m2));
        B = B + cos(theta)*(PC(k,m_t)*I*Mo)/(2*pi*sqrt((X-Xk)^2 + (Y-Yk)^2));
    end
    BCAP = B;
end