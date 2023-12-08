%% Decription
% Here we demonstrate how the optical properties can depend on the "damage"
% (coagulation/denaturation/reactions) that can occur with elevated
% temperatures, as described in the model.HS.Omega matrix using the
% Arrhenius damage integral formalism. The thermal properties can also
% depend on Omega, although we do not show it here. The example is supposed
% to model egg white resting on a black absorber surface, with a laser beam
% incident from above. As the absorber and the egg white heats, the egg
% white denaturates and becomes opaque (highly scattering), preventing most
% of the light from reaching the black absorber and slowing the process.
%
% The dependence of the optical or thermal properties is specified in the
% same way as in examples 12, 13 and 14, just using "FD" (Fractional
% Damage) in the char array describing the formula. FD = 1 - exp(-Omega) is
% a slightly more handy quantity to use than Omega, since it describes the
% relative quantity of molecules or cells that have undergone the chemical
% change, starting at 0 and tending asymptotically to 1, unlike Omega which
% goes to infinity.
%
% At the end of the simulation photons paths are shown which illustrate
% that the photons are scattered in the top part of the denatured "dome" of
% egg white and most of them do not reach the absorber.
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
model.MC.simulationTimeRequested  = .05; % [min] Time duration of the simulation

model.MC.matchedInterfaces        = true; % Assumes all refractive indices are the same
model.MC.boundaryType             = 1; % 0: No escaping boundaries, 1: All cuboid boundaries are escaping, 2: Top cuboid boundary only is escaping, 3: Top and bottom boundaries are escaping, while the side boundaries are cyclic
model.MC.wavelength               = 532; % [nm] Excitation wavelength, used for determination of optical properties for excitation light
model.MC.nExamplePaths            = 50;

model.MC.lightSource.sourceType   = 4; % 0: Pencil beam, 1: Isotropically emitting line or point source, 2: Infinite plane wave, 3: Laguerre-Gaussian LG01 beam, 4: Radial-factorizable beam (e.g., a Gaussian beam), 5: X/Y factorizable beam (e.g., a rectangular LED emitter)
model.MC.lightSource.focalPlaneIntensityDistribution.radialDistr = 0; % Radial focal plane intensity distribution - 0: Top-hat, 1: Gaussian, Array: Custom. Doesn't need to be normalized.
model.MC.lightSource.focalPlaneIntensityDistribution.radialWidth = .015; % [cm] Radial focal plane 1/e^2 radius if top-hat or Gaussian or half-width of the full distribution if custom
model.MC.lightSource.angularIntensityDistribution.radialDistr = 1; % Radial angular intensity distribution - 0: Top-hat, 1: Gaussian, 2: Cosine (Lambertian), Array: Custom. Doesn't need to be normalized.
model.MC.lightSource.angularIntensityDistribution.radialWidth = 10/180*pi; % [rad] Radial angular 1/e^2 half-angle if top-hat or Gaussian or half-angle of the full distribution if custom. For a diffraction limited Gaussian beam, this should be set to model.MC.wavelength*1e-9/(pi*model.MC.lightSource.focalPlaneIntensityDistribution.radialWidth*1e-2))
model.MC.lightSource.xFocus       = 0; % [cm] x position of focus
model.MC.lightSource.yFocus       = 0; % [cm] y position of focus
model.MC.lightSource.zFocus       = 0.08; % [cm] z position of focus
model.MC.lightSource.theta        = 0; % [rad] Polar angle of beam center axis
model.MC.lightSource.phi          = 0; % [rad] Azimuthal angle of beam center axis


model = runMonteCarlo(model);
model = plot(model,'MC');

%% Heat simulation
model.MC.P                   = 0.5; % [W] Incident pulse peak power (in case of infinite plane waves, only the power incident upon the cuboid's top surface)

model.HS.largeTimeSteps      = true; % (Default: false) If true, calculations will be faster, but some voxel temperatures may be slightly less precise. Test for yourself whether this precision is acceptable for your application.

model.HS.heatBoundaryType    = 1; % 0: Insulating boundaries, 1: Constant-temperature boundaries (heat-sinked)
model.HS.durationOn          = 0.02; % [s] Pulse on-duration
model.HS.durationOff         = 0.00; % [s] Pulse off-duration
model.HS.durationEnd         = 0.02; % [s] Non-illuminated relaxation time to add to the end of the simulation to let temperature diffuse after the pulse train
model.HS.T                   = 20; % [deg C] Initial temperature

model.HS.nPulses             = 1; % Number of consecutive pulses, each with an illumination phase and a diffusion phase. If simulating only illumination or only diffusion, use nPulses = 1.

model.HS.plotTempLimits      = [20 130]; % [deg C] Expected range of temperatures, used only for setting the color scale in the plot
model.HS.nUpdates            = 30; % Number of times data is extracted for plots during each pulse. A minimum of 1 update is performed in each phase (2 for each pulse consisting of an illumination phase and a diffusion phase)
model.HS.mediaPropRecalcPeriod = 5; % Every N updates, the media properties will be recalculated (including, if needed, re-running MC and FMC steps)

model.HS.tempSensorPositions = [0 0 0.065
  0 0 0.075
  0 0 0.085]; % Each row is a temperature sensor's absolute [x y z] coordinates. Leave the matrix empty ([]) to disable temperature sensors.


model = simulateHeatDistribution(model);
model = plot(model,'HS');
model = plot(model,'MC');

%% Geometry function(s) (see readme for details)
function M = geometryDefinition(X,Y,Z,parameters)
  M = ones(size(X)); % fill background with water
  M(Z > 0.03) = 2; % egg white
  M(Z > 0.08) = 3; % absorber
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
  mediaProperties(j).name  = 'egg white';
  mediaProperties(j).mua   = 1; % [cm^-1]
  mediaProperties(j).mus   = @musfunc2;
  function mus = musfunc2(wavelength,FR,T,FD)
    mus = 1+1000*FD; % [cm^-1]
  end
  mediaProperties(j).g     = 0.5;
  mediaProperties(j).VHC   = 4.19; % [J cm^-3 K^-1]
  mediaProperties(j).TC    = 5.8e-3; % [W cm^-1 K^-1]
  mediaProperties(j).E     = 390e3; % J/mol    PLACEHOLDER DATA ONLY
  mediaProperties(j).A     = 7.6e67; % 1/s        PLACEHOLDER DATA ONLY
  mediaProperties(j).nBins = 20;

  j=3;
  mediaProperties(j).name  = 'absorber';
  mediaProperties(j).mua   = 300; % [cm^-1]
  mediaProperties(j).mus   = 100; % [cm^-1]
  mediaProperties(j).g     = 0.9;
  mediaProperties(j).VHC   = 4.19; % [J cm^-3 K^-1]
  mediaProperties(j).TC    = 5.8e-3; % [W cm^-1 K^-1]
end