function h_f = plotMediaProperties(nFig,model)
  h_f = figure(nFig);
  set(h_f,'WindowStyle','Docked');
  clf reset;
  h_f.Color = 'w';
  cmap = colormap(lines);
  G = model.G;

  T = NaN([G.nx G.ny G.nz],'single');
  T(:) = model.HS.T; % model.HS.T may be scalar or 3D

  FD = NaN([G.nx G.ny G.nz],'single');
  FD(:) = 1 - exp(-model.HS.Omega); % Fractional damage of molecules/cells. model.HS.Omega may be scalar 0 or 3D

  FR = NaN([G.nx G.ny G.nz],'single');
  FR(:) = model.MC.P*sum(model.MC.NFR,4); % All excitation wavelengths are summed to get the total fluence rate. model.MC.NFR may be scalar 0 or 3D or 4D

  mP_fH = model.G.mediaPropertiesFunc(G.mediaPropParams);
  [trimmedMediaIdxs,~,M_trim] = unique(G.M_raw);
  mP_fHtrim = mP_fH(trimmedMediaIdxs);
  nM = numel(mP_fHtrim);
  names = {mP_fHtrim.name};
  Ls = unique([model.MC.wavelength model.FMC.wavelength]);
  Ls = Ls(~isnan(Ls));
  nL = numel(Ls);

  maxmuas = NaN(nM,nL);
  maxmuss = NaN(nM,nL);
  maxgs = NaN(nM,nL);
  minmuas = NaN(nM,nL);
  minmuss = NaN(nM,nL);
  mings = NaN(nM,nL);
  maxQYs = NaN(nM,nL);
  minQYs = NaN(nM,nL);
  maxESs = NaN(nM,nL); % Emission spectrum
  minESs = NaN(nM,nL);
  ns = NaN(nM,nL); % Refractive indexes
  maxVHCs = NaN(nM,1);
  maxTCs = NaN(nM,1);
  minVHCs = NaN(nM,1);
  minTCs = NaN(nM,1);
  for iM = 1:nM
    idxs = M_trim == iM;
    FRs = FR(idxs);
    Ts = T(idxs);
    FDs = FD(idxs);
    for iL = 1:nL
      muavalues = mP_fHtrim(iM).mua(Ls(iL),FRs,Ts,FDs);
      musvalues = mP_fHtrim(iM).mus(Ls(iL),FRs,Ts,FDs);
      gvalues = mP_fHtrim(iM).g(Ls(iL),FRs,Ts,FDs);
      QYvalues = 100*mP_fHtrim(iM).QY(Ls(iL),FRs,Ts,FDs);
      ESvalues = mP_fHtrim(iM).ES(Ls(iL),FRs,Ts,FDs);
      ns(iM,iL) = mP_fHtrim(iM).n(Ls(iL));
      maxmuas(iM,iL) = max(muavalues(:));
      minmuas(iM,iL) = min(muavalues(:));
      maxmuss(iM,iL) = max(musvalues(:));
      minmuss(iM,iL) = min(musvalues(:));
      maxgs(iM,iL) = max(gvalues(:));
      mings(iM,iL) = min(gvalues(:));
      QYvalues(isnan(QYvalues)) = 0;
      maxQYs(iM,iL) = max(QYvalues(:));
      minQYs(iM,iL) = min(QYvalues(:));
      ESvalues(isnan(ESvalues)) = 0;
      maxESs(iM,iL) = max(ESvalues(:));
      minESs(iM,iL) = min(ESvalues(:));
    end
    maxESs(iM,:) = maxESs(iM,:)/trapz(Ls,maxESs(iM,:)); % Normalize visualization of emission spectra to unit integral
    minESs(iM,:) = minESs(iM,:)/trapz(Ls,minESs(iM,:)); % Normalize visualization of emission spectra to unit integral
    VHCvalues = mP_fHtrim(iM).VHC(T(idxs),FD(idxs));
    maxVHCs(iM) = max(VHCvalues(:));
    minVHCs(iM) = min(VHCvalues(:));
    TCvalues = mP_fHtrim(iM).TC(T(idxs),FD(idxs));
    maxTCs(iM) = max(TCvalues(:));
    minTCs(iM) = min(TCvalues(:));
  end
  NFidxs = find(max(maxQYs,[],2) == 0); % Non-fluorescing media indexes
  
  maxESs(NFidxs,:) = NaN; minESs(NFidxs,:) = NaN;

  nAxes = 2 + any(~isnan(maxgs(:))) + 2*any(maxQYs(:) > 0) + 2*(all(isfinite(maxVHCs(:))) && all(isfinite(maxTCs(:))));
  switch nAxes
    case 2
      rows = 2;
      columns = 1;
    case {3,4}
      rows = 2;
      columns = 2;
    case {5,6}
      rows = 2;
      columns = 3;
    case {7,8,9}
      rows = 3;
      columns = 3;
  end
  
  iA = 1; % Index of axes
  subplot(rows,columns,iA); iA = iA + 1;
  plotProperty(Ls,maxmuas,minmuas,names,cmap);
  ylabel('Absorption coeff. \mu_a [cm^{-1}]');
  subplot(rows,columns,iA); iA = iA + 1;
  plotProperty(Ls,maxmuss,minmuss,names,cmap);
  ylabel('Scattering coeff. \mu_s [cm^{-1}]');
  if any(~isnan(maxgs(:)))
    subplot(rows,columns,iA); iA = iA + 1;
    plotProperty(Ls,maxgs,mings,names,cmap);
    ylabel({'Henyey-Greenstein','scattering anisotropy g'});
  end
  if any(ns(:) ~= 1)
    subplot(rows,columns,iA); iA = iA + 1;
    plotProperty(Ls,ns,ns,names,cmap);
    ylabel('Refractive index');
  end
  if any(maxQYs(:) > 0)
    subplot(rows,columns,iA); iA = iA + 1;
    plotProperty(Ls,maxQYs,minQYs,names,cmap);
    ylabel('Fluorescence quantum yield [%]');
    subplot(rows,columns,iA); iA = iA + 1;
    plotProperty(Ls,maxESs,minESs,names,cmap);
    ylabel('Fluorescence emission spectrum');
  end
  if all(isfinite(maxVHCs(:))) && all(isfinite(maxTCs(:)))
    subplot(rows,columns,iA); iA = iA + 1;
    plotProperty(NaN,maxVHCs,minVHCs,names,cmap);
    ylabel('Volumetric heat capacity [J/(cm^3*K)]');
    subplot(rows,columns,iA); iA = iA + 1;
    plotProperty(NaN,maxTCs,minTCs,names,cmap);
    ylabel('Thermal conductivity [W/(cm*K)]');
  end
end

function plotProperty(L,maxvals,minvals,names,cmap)
  lambdatext = [955 ' [nm]']; % The 955 is the unicode number for the lambda character. Because the editors of MATLAB versions prior to 2020a do not support unicode, we have to make the lambda in this sneaky way.
  hold on;
  nameCellArray = [];
  if numel(L) == 1
    barIdx = 1;
    for iM = 1:size(maxvals,1)
      if isequaln(maxvals(iM),minvals(iM))
        bar(barIdx,maxvals(iM),'FaceColor',cmap(iM,:));
        barIdx = barIdx+1;
        nameCellArray = [nameCellArray names(iM)]; %#ok<AGROW>
      else
        bar(barIdx,minvals(iM),'FaceColor',cmap(iM,:));
        barIdx = barIdx+1;
        bar(barIdx,maxvals(iM),'FaceColor',cmap(iM,:));
        barIdx = barIdx+1;
        nameCellArray = [nameCellArray {[names{iM} ' min']} {[names{iM} ' max']}]; %#ok<AGROW>
      end
    end
    h_ax = gca;
    set(h_ax,'XTick',1:(barIdx-1),'XTickLabel',nameCellArray,'XTickLabelRotation',45,'Box','on','YGrid','on','YMinorGrid','on');
    set(h_ax.XAxis,'FontSize',8);
  else
    for iM = 1:size(maxvals,1)
      if isequaln(maxvals(iM,:),minvals(iM,:))
        plot(L,maxvals(iM,:),'linewidth',2,'marker','o');
        nameCellArray = [nameCellArray , names(iM)]; %#ok<AGROW>
      else
        plot(L,minvals(iM,:),'linewidth',2,'marker','o');
        plot(L,maxvals(iM,:),'linewidth',2,'marker','o');
        nameCellArray = [nameCellArray {[names{iM} ' min']} {[names{iM} ' max']}]; %#ok<AGROW>
      end
    end
    grid on; grid minor; box on;
    xlabel(lambdatext);
    legend(nameCellArray,'FontSize',8,'Location','best');
  end
end