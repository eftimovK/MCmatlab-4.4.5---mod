%% Decription
% This example showcases the option of letting the thermal media properties
% depend on temperature. A medium is defined that has a volumetric heat
% capacity (VHC) that increases drastically when the temperature is around
% 40�C. Such a medium is not particularly realistic, but serves to
% showcase the feature.
%
% As the medium heats up, the regions that approach 40�C will not heat
% much further due to the very high VHC, despite still absorbing the same
% power as before. In the plot, the yellow color (40�C) can be seen to
% extend further and further down into the medium as time goes, but even
% the top layer has not become white (45�C) by the end of the
% simulation.
%
% In models where optical or thermal properties depend on temperature or
% fractional damage, it is very important for the user to test whether
% mediaProperties(j).nBins and model.HS.nUpdates are set high enough and
% model.HS.mediaPropRecalcPeriod low enough for a suitably converged
% result.

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

model.G.nx                = 100; % Number of bins in the x direction
model.G.ny                = 100; % Number of bins in the y direction
model.G.nz                = 100; % Number of bins in the z direction
model.G.Lx                = .1; % [cm] x size of simulation cuboid
model.G.Ly                = .1; % [cm] y size of simulation cuboid
model.G.Lz                = .1; % [cm] z size of simulation cuboid

model.G.mediaPropertiesFunc = @mediaPropertiesFunc; % Media properties defined as a function at the end of this file
model.G.geomFunc          = @geometryDefinition; % Function to use for defining the distribution of media in the cuboid. Defined at the end of this m file.

model = plot(model,'G');

%% Monte Carlo simulation
model.MC.simulationTimeRequested  = .1; % [min] Time duration of the simulation

model.MC.matchedInterfaces        = true; % Assumes all refractive indices are the same
model.MC.boundaryType             = 1; % 0: No escaping boundaries, 1: All cuboid boundaries are escaping, 2: Top cuboid boundary only is escaping, 3: Top and bottom boundaries are escaping, while the side boundaries are cyclic
model.MC.wavelength               = 532; % [nm] Excitation wavelength, used for determination of optical properties for excitation light

model.MC.lightSource.sourceType   = 4; % 0: Pencil beam, 1: Isotropically emitting line or point source, 2: Infinite plane wave, 3: Laguerre-Gaussian LG01 beam, 4: Radial-factorizable beam (e.g., a Gaussian beam), 5: X/Y factorizable beam (e.g., a rectangular LED emitter)
model.MC.lightSource.focalPlaneIntensityDistribution.radialDistr = 0; % Radial focal plane intensity distribution - 0: Top-hat, 1: Gaussian, Array: Custom. Doesn't need to be normalized.
model.MC.lightSource.focalPlaneIntensityDistribution.radialWidth = .03; % [cm] Radial focal plane 1/e^2 radius if top-hat or Gaussian or half-width of the full distribution if custom
model.MC.lightSource.angularIntensityDistribution.radialDistr = 0; % Radial angular intensity distribution - 0: Top-hat, 1: Gaussian, 2: Cosine (Lambertian), Array: Custom. Doesn't need to be normalized.
model.MC.lightSource.angularIntensityDistribution.radialWidth = 0; % [rad] Radial angular 1/e^2 half-angle if top-hat or Gaussian or half-angle of the full distribution if custom. For a diffraction limited Gaussian beam, this should be set to model.MC.wavelength*1e-9/(pi*model.MC.lightSource.focalPlaneIntensityDistribution.radialWidth*1e-2))
model.MC.lightSource.xFocus       = 0; % [cm] x position of focus
model.MC.lightSource.yFocus       = 0; % [cm] y position of focus
model.MC.lightSource.zFocus       = 0; % [cm] z position of focus
model.MC.lightSource.theta        = 0; % [rad] Polar angle of beam center axis
model.MC.lightSource.phi          = 0; % [rad] Azimuthal angle of beam center axis


model = runMonteCarlo(model);
model = plot(model,'MC');

%% Heat simulation
model.MC.P                   = 2; % [W] Incident pulse peak power (in case of infinite plane waves, only the power incident upon the cuboid's top surface)

model.HS.largeTimeSteps      = true; % (Default: false) If true, calculations will be faster, but some voxel temperatures may be slightly less precise. Test for yourself whether this precision is acceptable for your application.

model.HS.heatBoundaryType    = 0; % 0: Insulating boundaries, 1: Constant-temperature boundaries (heat-sinked)
model.HS.durationOn          = 0.02; % [s] Pulse on-duration
model.HS.durationOff         = 0.000; % [s] Pulse off-duration
model.HS.durationEnd         = 0.00; % [s] Non-illuminated relaxation time to add to the end of the simulation to let temperature diffuse after the pulse train
model.HS.T                   = 20; % [deg C] Initial temperature

model.HS.plotTempLimits      = [20 45]; % [deg C] Expected range of temperatures, used only for setting the color scale in the plot
model.HS.nUpdates            = 100; % Number of times data is extracted for plots during each pulse. A minimum of 1 update is performed in each phase (2 for each pulse consisting of an illumination phase and a diffusion phase)
model.HS.mediaPropRecalcPeriod = 1; % Every N updates, the media properties will be recalculated (including, if needed, re-running MC and FMC steps)
model.HS.slicePositions      = [.5 0.6 1]; % Relative slice positions [x y z] for the 3D plots on a scale from 0 to 1
model.HS.tempSensorPositions = [0 0 0.005
  0 0 0.015
  0 0 0.035
  0 0 0.065]; % Each row is a temperature sensor's absolute [x y z] coordinates. Leave the matrix empty ([]) to disable temperature sensors.


model = simulateHeatDistribution(model);
model = plot(model,'HS');

%% Geometry function(s) (see readme for details)
function M = geometryDefinition(X,Y,Z,parameters)
  M = ones(size(X)); % fill background with water
  M(Z > 0.01) = 2; % Temperature dependent VHC material
end

%% Media Properties function (see readme for details)
function mediaProperties = mediaPropertiesFunc(parameters)
  mediaProperties = MCmatlab.mediumProperties;

  j=1;
  mediaProperties(j).name  = 'water';
  mediaProperties(j).mua   = 0.00036; % [cm^-1]
  mediaProperties(j).mus   = 10; % [cm^-1]
  mediaProperties(j).g     = 1.0;
  mediaProperties(j).VHC   = 4.19; % [J cm^-3 K^-1]
  mediaProperties(j).TC    = 5.8e-3; % [W cm^-1 K^-1]

  j=2;
  mediaProperties(j).name  = 'temp. dep. VHC material';
  mediaProperties(j).mua = 30; % [cm^-1]
  mediaProperties(j).mus = 50; % [cm^-1]
  mediaProperties(j).g   = 0.8;
  mediaProperties(j).VHC = @VHCfunc2;
  function VHC = VHCfunc2(T,FD)
    VHC = 3.5 + 500./(1+exp(40-T)); % [J cm^-3 K^-1]
  end
  mediaProperties(j).TC  = 0.52e-2; % [W cm^-1 K^-1]
  mediaProperties(j).nBins = 30;
end