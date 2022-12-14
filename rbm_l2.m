if restart ==1,

epsilonw_0      = 0.05;   
epsilonvb_0     = 0.05;   
epsilonhb_0     = 0.05;

weightcost  = 0.001;   
initialmomentum  = 0.5;
finalmomentum    = 0.9;
vishid_l0 = vishid;
hidbiases_l0 = hidbiases;
visbiases_l0 = visbiases;
[numcases, numdims, numbatches]=size(batchdata);
numdims_l0 = numdims;

numdims = numhid;
numhid = numpen;

  restart=0;
  epoch=1;

% Initializing weights and biases. 
  vishid     = 0.01*randn(numdims, numhid);
  hidbiases  = zeros(1,numhid);
  visbiases  = zeros(1,numdims);

  poshidprobs = zeros(numcases,numhid);
  neghidprobs = zeros(numcases,numhid);
  posprods    = zeros(numdims,numhid);
  negprods    = zeros(numdims,numhid);
  vishidinc  = zeros(numdims,numhid);
  hidbiasinc = zeros(1,numhid);
  visbiasinc = zeros(1,numdims);

  numlab=10; 
  labhid = 0.01*randn(numlab,numhid);
  labbiases  = zeros(1,numlab);
  labhidinc =  zeros(numlab,numhid);
  labbiasinc =  zeros(1,numlab);

epoch=1;


end
population=0;
for epoch = epoch:maxepoch
 fprintf(1,'epoch %d\r',epoch); 

  CD = ceil(epoch/20);

  epsilonw = epsilonw_0/(1*CD);
  epsilonvb = epsilonvb_0/(1*CD);
  epsilonhb = epsilonhb_0/(1*CD);
 
 errsum=0;
 for batch = 1:numbatches,
      % START POSITIVE PHASE %
      data_l0 = batchdata(:,:,batch);
      poshidprobs_l0 = 1./(1 + exp(-data_l0*(2*vishid_l0) - repmat(2*hidbiases_l0,numcases,1)));
      data = poshidprobs_l0 > randaffectedByPopulation(numcases,numdims,population);
      targets = batchtargets(:,:,batch); 

      bias_hid= repmat(hidbiases,numcases,1);
      bias_vis = repmat(2*visbiases,numcases,1);
      bias_lab = repmat(labbiases,numcases,1);

      poshidprobs = 1./(1 + exp(-data*(vishid) - targets*labhid - bias_hid));    
      posprods    = data' * poshidprobs;
      posprodslabhid = targets'*poshidprobs;

      poshidact   = sum(poshidprobs);
      posvisact = sum(data);
      poslabact   = sum(targets);

    % END OF POSITIVE PHASE  %
      poshidprobs_temp = poshidprobs;

    % START NEGATIVE PHASE  %
      for cditer=1:CD
        poshidstates = poshidprobs_temp > rand(numcases,numhid);

        totin = poshidstates*labhid' + bias_lab;
        neglabprobs = exp(totin);
        neglabprobs = neglabprobs./(sum(neglabprobs,2)*ones(1,numlab));

        xx = cumsum(neglabprobs,2);
        xx1 = rand(numcases,1);
        neglabstates = neglabprobs*0;
        for jj=1:numcases
           index = min(find(xx1(jj) <= xx(jj,:)));
           neglabstates(jj,index) = 1;
        end
        xxx = sum(sum(neglabstates)) ;

        negdata = 1./(1 + exp(-poshidstates*(2*vishid)' - bias_vis));
        negdata = negdata > randaffectedByPopulation(numcases,numdims,population); 
        poshidprobs_temp = 1./(1 + exp(-negdata*(vishid) - neglabstates*labhid - bias_hid));
     end 
      neghidprobs = poshidprobs_temp;     

      negprods  = negdata'*neghidprobs;
      neghidact = sum(neghidprobs);
      negvisact = sum(negdata); 
      neglabact = sum(neglabstates);
      negprodslabhid = neglabstates'*neghidprobs;

    % END OF NEGATIVE PHASE %
      err= sum(sum( (data-negdata).^2 ));
      errsum = err + errsum;

       if epoch>5,
         momentum=finalmomentum;
       else
         momentum=initialmomentum;
       end;

    % UPDATE WEIGHTS AND BIASES %
        vishidinc = momentum*vishidinc + ...
                    epsilonw*( (posprods-negprods)/numcases - weightcost*vishid);
        labhidinc = momentum*labhidinc + ...
                epsilonw*( (posprodslabhid-negprodslabhid)/numcases - weightcost*labhid); 


        visbiasinc = momentum*visbiasinc + (epsilonvb/numcases)*(posvisact-negvisact);
        hidbiasinc = momentum*hidbiasinc + (epsilonhb/numcases)*(poshidact-neghidact);
        labbiasinc = momentum*labbiasinc + (epsilonvb/numcases)*(poslabact-neglabact);



        vishid = vishid + vishidinc;
        labhid = labhid + labhidinc;

        visbiases = visbiases + visbiasinc;
        hidbiases = hidbiases + hidbiasinc;
        labbiases = labbiases + labbiasinc;
        population=population+(3/(60000*maxepoch));
 end 
% END OF UPDATES %
  fprintf(1, 'epoch %4i error %6.1f  \n', epoch, errsum); 

% Look at the test scores %
  if rem(epoch,5)==0
    err =   testerr(testbatchdata,testbatchtargets,vishid_l0,hidbiases_l0,vishid,visbiases,hidbiases,labhid,labbiases);
    fprintf(1,'Number of misclassified test examples: %d out of 10000 \n',err);
  end

end;
