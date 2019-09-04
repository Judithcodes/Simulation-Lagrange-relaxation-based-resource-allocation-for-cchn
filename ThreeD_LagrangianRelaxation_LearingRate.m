function  [LRMatching,LRrate,LRTIME,LR_perform]=ThreeD_LagrangianRelaxation_LearingRate(CoeMat1,LearingRate)
%Input & Output
%CoeMat:original 3D matrix
%MaxIter:maxmum itertions
%H_fina:Up bound-feasible solution
%L_fina:Bottom bound-relax solution
%OptSolu:optimal solution
%iter:maxmum itertions for problem
t0=cputime;
maxV = max(max(max(CoeMat1)));%ת��Ϊ��С�Ż�
minV = min(min(min(CoeMat1)));%ת��Ϊ��С�Ż�

CoeMat=maxV-CoeMat1;

M=CoeMat;
[i1,i2,i3]=size(M);

%ǰ���������ؼ�����
% if maxV>0
%     LearingRate=0.001*(maxV-minV)/(maxV*5);
% else
%     LearingRate=0.0003;
% end
% LearingRate=1
InitLearingRate=LearingRate;
% % % LearingRate=0.000003732248;
% LearingRate=0.0000036315224812454;
% load LearingRate.mat LearingRate

MaxIter=20*i1^2;


A=zeros(i1,i2);%dual mat
u=zeros(1,1,i3);%lag Multiplier
LRrate=inf;
LRbound=-inf;
DualMatching=zeros(i1,3);
FinaMatching=zeros(i1,3);
L_init1=zeros(1,MaxIter);
H_init1=zeros(1,MaxIter);
Gap_init=zeros(1,MaxIter);

iter=0;
FailCount=0;
BreakCount=0;
Gap=100;
Withdraw=0;


while (BreakCount<MaxIter)&&Gap>0.0005&&(iter<20*i1^3)&&(Withdraw==0)
    iter=iter+1;
    %     LearingRate
    %% ��Ϊ2D ���ɳڽ�
    for i=1:i1
        for j=1:i2
            A(i,j)=min(M(i,j,:));
        end
    end
    
    [DualMat,L]=Hungarian(A);
    L=L+sum(u);
    %D2D-CU ���ƥ��
    for i=1:i1
        DualMatching(i,1)=i; %D2D
        FinaMatching(i,1)=i;
        DualMatching(i,2)=find(DualMat(i,:)==1);%CU
        FinaMatching(i,2)=find(DualMat(i,:)==1);
    end
    
    %% ͳ��i3���ظ�����
    B=zeros(i1,i3);
    for i=1:i1
        for j=1:i3
            B(i,j)=M(DualMatching(i,1),DualMatching(i,2),j);
        end
    end
    g=ones(1,1,i3);
    for i=1:i3
        k=find(B(i,:)==min(B(i,:)));
        DualMatching(i,3)=k(1);
        for j=1:i1
            n=find(B(j,:)==min(B(j,:)));
            if i==n(1)%find(DualAssiMat(i,:)==min(DualAssiMat(i,:)));
                g(1,1,i)=g(1,1,i)-1;
            end
        end
    end
    
    %% �������н���󣬿��н�
    C=zeros(i1,i3);
    for i=1:i1
        for j=1:i3
            C(i,j)=CoeMat(DualMatching(i,1),DualMatching(i,2),j);
        end
    end
    [FeaMat,H]=Hungarian(C);
    for i=1:i1
        FinaMatching(i,3)=find(FeaMat(i,:)==1);
    end
    
    %% ѧϰ����Ӧ��
    maxV1 = max(max(max(M)));%ת��Ϊ��С�Ż�
    minV1 = min(min(min(M)));%ת��Ϊ��С�Ż�
    if (maxV1-minV1)/(maxV1*2)>0
        K= (maxV1-minV1)/(maxV1*2);
    else
        K=1/5;
    end
    if H< LRrate%���н�����
        BestU=u;
        BestM=M;
        LRMatching=FinaMatching;
        LearingRate=LearingRate+0.000000005*K;
        FailCount=0;
        BreakCount=0;
    else
        FailCount=FailCount+1;
        if FailCount>20 %�����н�û���½����п��ܹ����ڣ�����ѧϰ��
            LearingRate=LearingRate+0.0000001*i3*(((BreakCount+5)/1000))*K;
            FailCount=0;
            if FailCount>30
                u=BestU;
                M=BestM;
                maxV1 = max(max(max(M)));%ת��Ϊ��С�Ż�
                minV1 = min(min(min(M)));%ת��Ϊ��С�Ż�
                if (maxV1-minV1)/(maxV1*2)>0
                    K= (maxV1-minV1)/(maxV1*2);
                else
                    K=1/5;
                end
                LearingRate=InitLearingRate+0.000000005*K;
            end
        end
        BreakCount=BreakCount+1;
    end
    %% �������Ž�
    LRrate=min(LRrate,H);
    LRbound=max(LRbound,L);
    
    Gap=(LRrate-LRbound)/LRbound;
    
    H_init1(1,iter)=LRrate;
    L_init1(1,iter)=LRbound;
    Gap_init(1,iter)=Gap;
    
    
    %% ���Ӹ���
    if any(g)==0 %Լ�������Ѿ�����
        Withdraw=1;
    end
    u=u+LearingRate*((LRrate-LRbound)/(sum(g.^2)))*g;
    
    %         u=u+max(LearingRate*((LRrate-LRbound)/(sum(g.^2)))*g,0);
    
    
    %% �ͷ��������
    for i=1:i3
        M(DualMatching(i,1),DualMatching(i,2),DualMatching(i,3))...
            =M(DualMatching(i,1),DualMatching(i,2),DualMatching(i,3))...
            -u(1,1,DualMatching(i,3));
    end
    
end
LRTIME=cputime-t0;
LRrate=i1*maxV-LRrate;

H_init1=i1*maxV-H_init1;
L_init1=i1*maxV-L_init1;
%iter=size(L_init1,2)
LR_perform=[1:iter ;H_init1(1,1:iter) ;L_init1(1,1:iter);1:iter ];

% LRinform=['End']
%len=iter;
% figure
% plot(1:len,L_init1(1,1:len),'-ro','linewidth',1.5,'MarkerSize',1)
% hold on
% plot(1:len,H_init1(1,1:len),'-v','linewidth',1.5,'MarkerSize',1)
% hold on
% xlabel({'The number of iterations'},'FontName','Times New Roman','FontSize',13);
% ylabel({'Sum-rate  (nat/s)'},'FontName','Times New Roman','FontSize',13);
% 
% s2=legend('R^{fea}','R^{dua}',0); %4,Lower right corner
% set(s2,'FontName','Times New Roman','FontSize',12);
% grid on
% 
% formatOut = 'yy_mm_dd';
% SimuTimeHistory=datestr(now,formatOut);
% FigurePath=['����ͼƬ\Experiment_20' SimuTimeHistory '\'];
% FigFormat='.fig';
% FileName='LR_R_dua-R_fea';
% saveas(gcf,[FigurePath FileName FigFormat]);