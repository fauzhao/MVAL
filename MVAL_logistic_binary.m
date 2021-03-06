function [next_index, fnum] = MVAL_logistic_binary(X, Y, Dl, Du) 
% This code refers to MVAL using logistic regression as the classifier on binary tasks
% 
%  Syntax
%       next_index = MVAL_logistic_binary(X, Y, Dl, Du)
%    
%  Description
%       Setting: We have a data set X with n instances, n1 of them are labeled (queried) and the others are unlabeled. The i-th instance is stored in X(i,:);
%       Task:   choose the next queried data point.
%         
%  Input: 
%       X     - A n x D array, the pool of availabel data, where N is the number of samples and D is the feature dimensionality;
%       Y     - A n x 1 vector, the true labels of samples in X, e.g. +1: postive class, -1: negative class;
%       Dl    - A 1 x n1 vector, the index of labeled instances
%       Du    - A 1 x (n-n1) vector, the index of unlabeled instances          
%       
% 
%  Output:
%        next_index - An integer, the index of the selected instance for query, i.e., the label of X(next_index,:) is to be queried;
%   
%  If you are using this code, please consider citing the following reference:
% 
%  Reference: Yang, Yazhou, and Marco Loog. "A variance maximization criterion for active learning." Pattern Recognition 78 (2018): 358-370.
%  
%  (C) Yazhou Yang, 2018
%  Email: yazhouy@gmail.com
%  Delft University of Technology

%%

% get the labeled data and unlabeled data
Ldata = X(Dl',:);
Llabel = Y(Dl',:);

Udata = X(Du',:);
Ulabel = Y(Du',:);

% train the model using liblinear, logistic regression, and calculate the posterior probability
model = lineartrain(Llabel, sparse(Ldata), '-s 0 -c 100 -B 1 -q');
[~, ~, dec_values] = linearpredict(Ulabel, sparse(Udata), model,'-b 1 -q');

% estimate the weight, i.e. Entropy e_j
entropy = (-1)*sum(dec_values.*log(dec_values+1e-100),2)/log(2);

Kclass = length(unique(Y));

if Kclass>2
   error('This function is for binary datasets! Please consider using MVAL_logistic_multi.m!');
end


sto = zeros(size(Du,2),size(Y,1),Kclass^2);

ny = unique(Y);
%% generate the Retraining information matrices (RIMs)

% goes over all the unlabeled data 
for num = 1:size(Du,2)
    % add Du(num) to the labeled data 
    newDl = [Dl Du(num)];    
    newLdata = X(newDl',:);
        
    newLlabel = [Llabel; ny(1)];    
    newmodel = lineartrain(newLlabel, sparse(newLdata), '-s 0 -c 100 -B 1 -q');
    [~, ~, prob_Upos] = linearpredict(Y, sparse(X), newmodel,'-b 1 -q');
       
    newLlabel = [Llabel; ny(2)];  
    newmodel = lineartrain(newLlabel, sparse(newLdata), '-s 0 -c 100 -B 1 -q');
    [~, ~, prob_Uneg] = linearpredict(Y, sparse(X), newmodel,'-b 1 -q');
    
    sto(num,:,:) = [prob_Upos  prob_Uneg];
end
 
%% compute the variance of V1 and V2 for binary dataset

st1 = sto(:,:,1);
st2 = sto(:,:,3);

P = st1(:,Du); 
N = st2(:,Du); 

% weighted P and N
P_hat = P.*repmat(entropy',length(Du),1);
N_hat = N.*repmat(entropy',length(Du),1);

A = [P_hat;N_hat];
B = [P_hat-N_hat]';

V1 = var(A);
V2 = var(B);

value = V1.*V2;
%%  select the next point
[~,ind] = sort(value,'descend');

fnum = ind(1);
next_index = Du(fnum);

%% Dl and Du can be updated as follows:
% Dl = [Dl next_index];
% Du(fnum) = [];

end
