%% Description
% This example is another illustration of MC simulations inside a for loop,
% this time simulating a pencil beam incident on a 100 �m slab of scattering
% medium with a variable (parametrically sweeped) scattering anisotropy g.
% g is passed in through the mediaPropParams field and used within
% mediaPropertiesFunc. Light is collected in transmission at a 45� angle in
% a fiber, similar to example 8. At the end of the script, collected power
% as a function of g is plotted. The power is seen to be zero for g = +- 1,
% which is because then the light can only be scattered exactly forward or
% backward. The max is at about 0.6, fitting well with a single scattering
% event at 45�. There is a secondary hump around -0.7, which fits with
% photons experiencing two scattering events at a scattering angle of
% 157.5�.
%
% As in example 9, calcNFR is again set to false to speed up the simulation
% slightly.
%
% The results of the last run will be plotted and MCmatlab will give a
% warning because in that last one, no photons were collected in the
% detector. This is not a problem in our case since we were expecting this.

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

model.G.silentMode        = true; % Disables command window text and progress indication

model.G.nx                = 21; % Number of bins in the x direction
model.G.ny                = 21; % Number of bins in the y direction
model.G.nz                = 21; % Number of bins in the z direction
model.G.Lx                = .1; % [cm] x size of simulation cuboid
model.G.Ly                = .1; % [cm] y size of simulation cuboid
model.G.Lz                = .01; % [cm] z size of simulation cuboid

model.G.mediaPropertiesFunc = @mediaPropertiesFunc; % Media properties defined as a function at the end of this file
model.G.geomFunc          = @geometryDefinition; % Function to use for defining the distribution of media in the cuboid. Defined at the end of this m file.

%% Monte Carlo simulation
model.MC.silentMode               = true; % Disables command window text and progress indication
model.MC.useAllCPUs               = true; % If false, MCmatlab will leave one processor unused. Useful for doing other work on the PC while simulations are running.
model.MC.simulationTimeRequested  = 2/60; % [min] Time duration of the simulation
model.MC.calcNormalizedFluenceRate = false; % (Default: true) If true, the 3D normalized fluence rate output matrix will be calculated. Set to false if you have a light collector and you're only interested in the image output.

model.MC.matchedInterfaces        = true; % Assumes all refractive indices are the same
model.MC.boundaryType             = 1; % 0: No escaping boundaries, 1: All cuboid boundaries are escaping, 2: Top cuboid boundary only is escaping, 3: Top and bottom boundaries are escaping, while the side boundaries are cyclic
model.MC.wavelength               = 532; % [nm] Excitation wavelength, used for determination of optical properties for excitation light

model.MC.lightSource.sourceType   = 0; % 0: Pencil beam, 1: Isotropically emitting line or point source, 2: Infinite plane wave, 3: Laguerre-Gaussian LG01 beam, 4: Radial-factorizable beam (e.g., a Gaussian beam), 5: X/Y factorizable beam (e.g., a rectangular LED emitter)
model.MC.lightSource.xFocus       = 0; % [cm] x position of focus
model.MC.lightSource.yFocus       = 0; % [cm] y position of focus
model.MC.lightSource.zFocus       = 0; % [cm] z position of focus
model.MC.lightSource.theta        = 0; % [rad] Polar angle of beam center axis
model.MC.lightSource.phi          = 0; % [rad] Azimuthal angle of beam center axis

model.MC.useLightCollector        = true;
model.MC.lightCollector.x         = 0; % [cm] x position of either the center of the objective lens focal plane or the fiber tip
model.MC.lightCollector.y         = -0.05; % [cm] y position
model.MC.lightCollector.z         = 0.06; % [cm] z position

model.MC.lightCollector.theta     = 3*pi/4; % [rad] Polar angle of direction the light collector is facing
model.MC.lightCollector.phi       = pi/2; % [rad] Azimuthal angle of direction the light collector is facing

model.MC.lightCollector.f         = Inf; % [cm] Focal length of the objective lens (if light collector is a fiber, set this to Inf).
model.MC.lightCollector.diam      = .1; % [cm] Diameter of the light collector aperture. For an ideal thin lens, this is 2*f*tan(asin(NA)).
model.MC.lightCollector.fieldSize = .1; % [cm] Field Size of the imaging system (diameter of area in object plane that gets imaged). Only used for finite f.
model.MC.lightCollector.NA        = 0.22; % [-] Fiber NA. Only used for infinite f.

model.MC.lightCollector.res       = 1; % X and Y resolution of light collector in pixels, only used for finite f

%% Looping over the different scattering anisotropies g
g_vec = linspace(-1,1,21); % g values to simulate
power_vec = zeros(1,length(g_vec));
fprintf('%2d/%2d\n',0,length(g_vec));
for i=1:length(g_vec)
  fprintf('\b\b\b\b\b\b%2d/%2d\n',i,length(g_vec)); % Simple progress indicator

  % Adjust media properties
  model.G.mediaPropParams   = {g_vec(i)}; % Cell array containing any additional parameters to be passed to the mediaPropertiesFunc function

  % Run MC
  model = runMonteCarlo(model);

  % Post-processing
  power_vec(i) = model.MC.lightCollector.image; % "image" is in this case just a scalar, the normalized power collected by the fiber.
end
model = plot(model,'G');
model = plot(model,'MC');

%% Plotting the collected power vs. scattering anisotropy g
figure;clf;
plot(g_vec,power_vec,'Linewidth',2);
set(gcf,'Position',[40 80 800 550]);
xlabel('Scattering anisotropy g');
ylabel('Normalized power collected by fiber');
set(gca,'FontSize',18);grid on; grid minor;

%% Geometry function(s) (see readme for details)
function M = geometryDefinition(X,Y,Z,parameters)
  M = ones(size(X)); % Variable g medium
end

%% Media Properties function (see readme for details)
function mediaProperties = mediaPropertiesFunc(parameters)
  mediaProperties = MCmatlab.mediumProperties;

  j=1;
  mediaProperties(j).name  = 'variable g medium';
  mediaProperties(j).mua   = 10; % [cm^-1]
  mediaProperties(j).mus   = 100; % [cm^-1]
  mediaProperties(j).g = parameters{1};
end
