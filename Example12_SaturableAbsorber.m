%% Description
% Here we show an example of how to model fluence rate dependent optical
% properties. We have a beam of light incident exactly on the interface
% between two saturable absorber materials. Material 1 has an absorption
% coefficient that reduces with fluence rate, while for material 2 both the
% absorption and scattering coefficients drop with fluence rate, and the
% scattering anisotropy increases with fluence rate, asymptotially up to 1.
% The dependence are written as MATLAB function handles in the media
% properties at the bottom of the file. In the formulas, FR is simply the
% normalized fluence rate times the power, FR =
% model.MC.normalizedFluenceRate*model.MC.P.
%
% When simulating fluence rate or temperature dependent optical or thermal
% properties, the algorithm "bins" voxels of similar optical or thermal
% properties together. The number of bins used for fluence rate,
% temperature or damage fraction dependence is specified in the
% mediaProperties(j).nBins property of each of the relevant media. In other
% words, if nBins = 3, that medium will be split into "low fluence rate",
% "medium fluence rate" and "high fluence rate" sub-media with different
% (mua, mus, g) as far as the Monte Carlo algorithm is concerned. The total
% number of (sub-)media must not exceed 256. For illustration purposes, the
% number of bins used for saturable absorber 2 is intentionally set low (9)
% so that the binning becomes visible as discontinuities in the absorption
% plot.
%
% The Monte Carlo simulation is run iteratively, using the previous run's
% fluence rate to determine the optical properties for the next run. The
% number of iterations is specified in model.MC.FRdepIterations, which is
% 20 by default. The specified simulation time or number of photons applies
% to the final iteration, while all the previous iterations will have
% shorter durations (scaling by a factor of 2 each time).
%
% It is the user's responsibility to check that mediaProperties(j).nBins
% and model.MC.FRdepIterations are high enough for a suitably converged
% result.
%
% In the result, you see that the collimated Gaussian beam narrows as it
% passes deeper in both of the saturable absorber media, which is because
% it is preferentially absorbed in the wings of the beam profile. The Media
% Properties figure show both the minimum and maximum achieved values of
% the optical properties for each of the saturable absorbers.

%% MCmatlab abbreviations
% G: Geometry, MC: Monte Carlo, FMC: Fluorescence Monte Carlo, HS: Heat
% simulation, M: Media array, FR: Fluence rate, FD: Fractional damage.
%
% There are also some optional abbreviations you can use when referencing
% object/variable names: LS = lightSource, LC = lightCollector, FPID =
% focalPlaneIntensityDistribution, AID = angularIntensityDistribution, NI =
% normalizedIrradiance, NFR = normalizedFluenceRate.
%
% For example, "model.MC.LS.FPID.radialDistr" is the same as
% "model.MC.lightSource.focalPlaneIntensityDistribution.radialDistr"

%% Geometry definition
MCmatlab.closeMCmatlabFigures();
model = MCmatlab.model;

model.G.nx                  = 100; % Number of bins in the x direction
model.G.ny                  = 100; % Number of bins in the y direction
model.G.nz                  = 200; % Number of bins in the z direction
model.G.Lx                  = .1; % [cm] x size of simulation cuboid
model.G.Ly                  = .1; % [cm] y size of simulation cuboid
model.G.Lz                  = .2; % [cm] z size of simulation cuboid

model.G.mediaPropertiesFunc = @mediaPropertiesFunc; % Media properties defined as a function at the end of this file
model.G.geomFunc            = @geometryDefinition; % Function to use for defining the distribution of media in the cuboid. Defined at the end of this m file.

model = plot(model,'G');

%% Monte Carlo simulation
model.MC.simulationTimeRequested  = .2; % [min] Time duration of the simulation

model.MC.matchedInterfaces        = true; % Assumes all refractive indices are the same
model.MC.boundaryType             = 1; % 0: No escaping boundaries, 1: All cuboid boundaries are escaping, 2: Top cuboid boundary only is escaping, 3: Top and bottom boundaries are escaping, while the side boundaries are cyclic
model.MC.wavelength               = 532; % [nm] Excitation wavelength, used for determination of optical properties for excitation light

model.MC.lightSource.sourceType   = 4; % 0: Pencil beam, 1: Isotropically emitting line or point source, 2: Infinite plane wave, 3: Laguerre-Gaussian LG01 beam, 4: Radial-factorizable beam (e.g., a Gaussian beam), 5: X/Y factorizable beam (e.g., a rectangular LED emitter)
model.MC.lightSource.focalPlaneIntensityDistribution.radialDistr = 1; % Radial focal plane intensity distribution - 0: Top-hat, 1: Gaussian, Array: Custom. Doesn't need to be normalized.
model.MC.lightSource.focalPlaneIntensityDistribution.radialWidth = .02; % [cm] Radial focal plane 1/e^2 radius if top-hat or Gaussian or half-width of the full distribution if custom
model.MC.lightSource.angularIntensityDistribution.radialDistr = 1; % Radial angular intensity distribution - 0: Top-hat, 1: Gaussian, 2: Cosine (Lambertian), Array: Custom. Doesn't need to be normalized.
model.MC.lightSource.angularIntensityDistribution.radialWidth = 0; % [rad] Radial angular 1/e^2 half-angle if top-hat or Gaussian or half-angle of the full distribution if custom. For a diffraction limited Gaussian beam, this should be set to model.MC.wavelength*1e-9/(pi*model.MC.lightSource.focalPlaneIntensityDistribution.radialWidth*1e-2))
model.MC.lightSource.xFocus       = 0; % [cm] x position of focus
model.MC.lightSource.yFocus       = 0; % [cm] y position of focus
model.MC.lightSource.zFocus       = model.G.Lz/2; % [cm] z position of focus
model.MC.lightSource.theta        = 0; % [rad] Polar angle of beam center axis
model.MC.lightSource.phi          = 0; % [rad] Azimuthal angle of beam center axis

model.MC.FRinitial = zeros(model.G.nx,model.G.ny,model.G.nz); % [W/cm^2] Initial guess for the intensity distribution, to be used for fluence rate dependent simulations
model.MC.P = 5; % [W] Power incident on top area of cuboid, used for calculations with fluence rate-dependent properties or for heat simulations
model.MC.FRdepIterations = 15;


model = runMonteCarlo(model); % Iteratively run Monte Carlo the default number of times (20) with simulation time (or nPhotons) increasing by a factor of 2 each time. Last run has simulation time equal to MC.simulationTime (or nPhotons equal to MC.nPhotonsRequested).
model = plot(model,'MC');

%% Geometry function(s) (see readme for details)
function M = geometryDefinition(X,Y,Z,parameters)
  absorberdepth = 0.03;
  M = ones(size(X)); % Air
  M(Z > absorberdepth) = 2; % Saturable absorber 1
  M(Z > absorberdepth & Y > 0) = 3; % Saturable absorber 2
end

%% Media Properties function (see readme for details)
function mediaProperties = mediaPropertiesFunc(parameters)
  mediaProperties = MCmatlab.mediumProperties;

  j=1;
  mediaProperties(j).name    = 'air';
  mediaProperties(j).mua     = 1e-8; % [cm^-1]
  mediaProperties(j).mus     = 1e-8; % [cm^-1]
  mediaProperties(j).g       = 0;

  j=2;
  mediaProperties(j).name    = 'saturable absorber 1';
  mediaProperties(j).mua     = @func1; % [cm^-1]
  function mua = func1(lambda,FR,T,FD)
    mua = 50./(1+FR/2000);
  end
  mediaProperties(j).mus     = 10; % [cm^-1]
  mediaProperties(j).g       = 0.9;
  mediaProperties(j).nBins   = 50; % Number of bins to use for the fluence rate- or temperature dependent (FRTDep) simulations. Higher is better and slower

  j=3;
  mediaProperties(j).name    = 'saturable absorber 2';
  mediaProperties(j).mua     = @func2; % [cm^-1]
  function mua = func2(lambda,FR,T,FD)
    mua = 50./(1+FR/1000);
  end
  mediaProperties(j).mus     = @func3; % [cm^-1]
  function mus = func3(lambda,FR,T,FD)
    mus = 10./(1+FR/500);
  end
  mediaProperties(j).g       = @func4;
  function g = func4(lambda,FR,T,FD)
    g = 1 - 0.1./(1+FR/300);
  end
  mediaProperties(j).nBins   = 9; % Number of bins to use for the fluence rate- or temperature dependent (FRTDep) simulations. Higher is better and slower
end