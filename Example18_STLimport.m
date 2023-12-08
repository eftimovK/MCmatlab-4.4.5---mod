%% Description
% This example shows how to import a shape from an STL file (sample.stl)
% and optionally apply scaling (unit conversion), rotation and mirroring on
% the mesh before using a function to voxelise the mesh.
%
% Importing is done inside the geometry function at the end of the model
% file (this file). The function findInsideVoxels returns a logical 3D
% array which is true in the indices of those voxels that are inside the
% (watertight) shape stored in the STL file. The function takes six inputs.
% The first three are always just the X, Y, and Z arrays exactly as they
% are passed into the geometry function. The fourth is the file name of the
% STL file. The fifth is a 3x3 matrix A that will be multiplied onto the
% STL mesh [x;y;z] coordinates. The sixth is a 1D array v of length 3 that
% defines the translation that will be applied to the mesh points after
% multiplication and before voxelisation. In other words, the mesh points
% are transformed according to    [x';y';z'] = A*[x;y;z] + v     and the
% voxelisation is then performed based on the mesh with positions
% [x';y';z'].
%
% The multiplication matrix A can contain a scaling factor, e.g., for
% converting from the units of the STL file to centimeters, which is the
% unit used in MCmatlab. It can also contain various rotation matrices, see
% https://en.wikipedia.org/wiki/Rotation_matrix#In_three_dimensions
% You may also mirror the coordinates by inverting the sign of the
% appropriate elements in the matrix.
%
% The example runs four separate sub-examples showing various
% transformations. Press enter to advance from one sub-example to the next.
% The MC simulation is not run in this example.
%
% Remember that since the z-axis in MCmatlab points down, the coordinate
% system is a left-handed coordinate system. Therefore a rotation that is
% clockwise in a right-handed coordinate system will be counter-clockwise
% in MCmatlab's coordinate system.
%
% The STL import feature uses the mesh_voxelization code by William Warriner:
% https://github.com/wwarriner/mesh_voxelization
% although the function has been lightly modified by Anders K. Hansen for
% use in MCmatlab.

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
model.G.Lx                = 4; % [cm] x size of simulation cuboid
model.G.Ly                = 4; % [cm] y size of simulation cuboid
model.G.Lz                = 4; % [cm] z size of simulation cuboid

model.G.mediaPropertiesFunc = @mediaPropertiesFunc; % Media properties defined as a function at the end of this file

% No rotation or mirroring, only scaling to convert from mm to cm and a
% translation along +z:
model.G.geomFunc          = @geometryDefinition_1;
model = plot(model,'G');
figure(31); % Make the STL import illustration the active figure so we can see it
fprintf('Press enter to continue...\n');pause;

% Mirror along the z direction, scale and translate:
model.G.geomFunc          = @geometryDefinition_2;
model = plot(model,'G');
figure(31); % Make the STL import illustration the active figure so we can see it
fprintf('Press enter to continue...\n');pause;

% Rotate by pi/2 (90 degrees) around the x axis, then scale and translate:
model.G.geomFunc          = @geometryDefinition_3;
model = plot(model,'G');
figure(31); % Make the STL import illustration the active figure so we can see it
fprintf('Press enter to continue...\n');pause;

% Rotate by pi/2 (90 degrees) around the x axis, then -pi/2 (-90 degrees)
% around the z axis, then scale and translate:
model.G.geomFunc          = @geometryDefinition_4;
model = plot(model,'G');
figure(31); % Make the STL import illustration the active figure so we can see it

%% Geometry function(s) (see readme for details)
function M = geometryDefinition_1(X,Y,Z,parameters)
  % Don't rotate or mirror the STL mesh points, but convert the coordinates from mm to cm by multiplying by 0.1:
  A = 0.1*eye(3);

  % Then translate the points by 1.5 in the +z direction:
  v = [0 0 1.5];

  % Find out which voxels are located inside this mesh:
  insideVoxels = findInsideVoxels(X,Y,Z,'sample.stl',A,v);

  % Set the background to air and the inside voxels to standard tissue:
  M = ones(size(X)); % Air
  M(insideVoxels) = 2;
end

function M = geometryDefinition_2(X,Y,Z,parameters)
  % Invert the z-coordinates of the STL mesh points, and scale the result by 0.1:
  A = 0.1*[1  0  0;
           0  1  0;
           0  0 -1];

  % Then translate the points by 2.5 in the +z direction:
  v = [0 0 2.5];

  % Find out which voxels are located inside this mesh:
  insideVoxels = findInsideVoxels(X,Y,Z,'sample.stl',A,v);

  % Set the background to air and the inside voxels to standard tissue:
  M = ones(size(X)); % Air
  M(insideVoxels) = 2;
end

function M = geometryDefinition_3(X,Y,Z,parameters)
  % First rotate the STL file mesh points by theta around the x axis, then scale by 0.1:
  theta = pi/2;
  A = 0.1*[1     0            0    ;
           0 cos(theta) -sin(theta);
           0 sin(theta)  cos(theta)]; % Rotation around the x axis

  % Then translate the mesh by 2.5 in the +z direction:
  v = [0 0 2.5];

  % Find out which voxels are located inside this mesh:
  insideVoxels = findInsideVoxels(X,Y,Z,'sample.stl',A,v);

  % Set the background to air and the inside voxels to standard tissue:
  M = ones(size(X)); % Air
  M(insideVoxels) = 2;
end

function M = geometryDefinition_4(X,Y,Z,parameters)
  % Construct some rotation matrices for rotation around the x and z axes:
  theta = pi/2;
  Rx = [   1         0           0     ;
           0     cos(theta) -sin(theta);
           0     sin(theta)  cos(theta)]; % Rotation around the x axis

  phi = -pi/2;
  Rz = [cos(phi) -sin(phi)       0     ;
        sin(phi)  cos(phi)       0     ;
           0         0           1     ]; % Rotation around the z axis

  % First rotate the STL file mesh points by theta around the x axis, then
  % phi around the z axis (multiplication onto [x;y;z] happens from right to
  % left), then scale by 0.1:
  A = 0.1*Rz*Rx;

  % Then translate the mesh by 2.5 in the +z direction:
  v = [0 0 2.5];

  % Find out which voxels are located inside this mesh:
  insideVoxels = findInsideVoxels(X,Y,Z,'sample.stl',A,v);

  % Set the background to air and the inside voxels to standard tissue:
  M = ones(size(X)); % Air
  M(insideVoxels) = 2;
end

%% Media Properties function (see readme for details)
function mediaProperties = mediaPropertiesFunc(parameters)
  mediaProperties = MCmatlab.mediumProperties;

  j=1;
  mediaProperties(j).name  = 'air';
  mediaProperties(j).mua   = 1e-8; % [cm^-1]
  mediaProperties(j).mus   = 1e-8; % [cm^-1]
  mediaProperties(j).g     = 1;

  j=2;
  mediaProperties(j).name  = 'standard tissue';
  mediaProperties(j).mua   = 1; % [cm^-1]
  mediaProperties(j).mus   = 100; % [cm^-1]
  mediaProperties(j).g     = 0.9;
end