%Cargar archivos
Dato1=readtable('Dato1.csv');
Dato2=readtable('Dato2.csv');
Dato3=readtable('Dato3.csv')

% Variables en el espacio de trabajo
datos = {Dato1, Dato2, Dato3};  

% Inicializar listas para almacenar envolventes y promedios de picos
envolventes_ax = cell(1, 3);
envolventes_ay = cell(1, 3);
envolventes_az = cell(1, 3);
picos_ax = cell(1, 3);
picos_ay = cell(1, 3);
picos_az = cell(1, 3);

% Procesar los datos
for n = 1:3
    data = datos{n};
    
    % Extraer componentes
    ax = 'data.axms2';
    ay = 'data.ayms2';
    az = 'data.azms2';
    
    % Calcular la envolvente usando la transformada de Hilbert
    envol_ax = abs(hilbert(ax));
    envol_ay = abs(hilbert(ay));
    envol_az = abs(hilbert(az));
    
    % Guardar las envolventes en las listas correspondientes
    envolventes_ax{n} = envol_ax;
    envolventes_ay{n} = envol_ay;
    envolventes_az{n} = envol_az;
    
    % Calcular los máximos en las envolventes
    [picos_ax{n}, ] = findpeaks(envol_ax);
    [picos_ay{n}, ] = findpeaks(envol_ay);
    [picos_az{n}, ] = findpeaks(envol_az);
    
    % Excluir los últimos 300 datos
    picos_ax{n} = picos_ax{n}(picos_ax{n} < length(envol_ax) - 300);
    picos_ay{n} = picos_ay{n}(picos_ay{n} < length(envol_ay) - 300);
    picos_az{n} = picos_az{n}(picos_az{n} < length(envol_az) - 300);
    
    % Seleccionar los 20 máximos principales respetando su posición
    if length(picos_ax{n}) > 20
        picos_ax{n} = envol_ax(picos_ax{n}(1:20));
        picos_ay{n} = envol_ay(picos_ay{n}(1:20));
        picos_az{n} = envol_az(picos_az{n}(1:20));
    else
        picos_ax{n} = envol_ax(picos_ax{n});
        picos_ay{n} = envol_ay(picos_ay{n});
        picos_az{n} = envol_az(picos_az{n});
    end
end

% Convertir listas a matrices para facilitar el cálculo de promedios
picos_ax = cell2mat(picos_ax');
picos_ay = cell2mat(picos_ay');
picos_az = cell2mat(picos_az');

% Calcular el promedio de los picos para cada posición (1º, 2º, ... 20º)
promedios_maximos_ax = mean(picos_ax, 1);
promedios_maximos_ay = mean(picos_ay, 1);
promedios_maximos_az = mean(picos_az, 1);

% Definir la función exponencial para el ajuste
exponencial = @(b, x) b(1) * exp(-b(2) * x) + b(3);

% Distancias correspondientes (0.2, 0.4, ..., 4.0 metros)
distancias = 0.5:0.5:4.0;

% Ajuste exponencial
try
    % Ajustar la curva exponencial
    b0 = [1, 0.01, 0]; % Valor inicial para [A, B, C]
    params_ax = nlinfit(distancias, promedios_maximos_ax, exponencial, b0);
    params_ay = nlinfit(distancias, promedios_maximos_ay, exponencial, b0);
    params_az = nlinfit(distancias, promedios_maximos_az, exponencial, b0);

    % Generar datos ajustados
    ajuste_ax = exponencial(params_ax, distancias);
    ajuste_ay = exponencial(params_ay, distancias);
    ajuste_az = exponencial(params_az, distancias);

    % Graficar las envolventes de todos los archivos en gráficos separados
    figure;
    for i = 1:3
        subplot(3, 3, (i-1)*3 + 1);
        plot(envolventes_ax{i}, 'b');
        title(sprintf('Envolvente de ax (Muestra %d)', i));
        xlabel('Muestras');
        ylabel('Amplitud (m/s²)');
        grid on;

        subplot(3, 3, (i-1)*3 + 2);
        plot(envolventes_ay{i}, 'g');
        title(sprintf('Envolvente de ay (Muestra %d)', i));
        xlabel('Muestras');
        ylabel('Amplitud (m/s²)');
        grid on;

        subplot(3, 3, (i-1)*3 + 3);
        plot(envolventes_az{i}, 'r');
        title(sprintf('Envolvente de az (Muestra %d)', i));
        xlabel('Muestras');
        ylabel('Amplitud (m/s²)');
        grid on;
    end

    % Graficar las amplitudes promedio y el ajuste exponencial
    figure;
    hold on;
    plot(distancias, promedios_maximos_ax, 'bo-', 'DisplayName', 'ax');
    plot(distancias, ajuste_ax, 'b--', 'DisplayName', 'Ajuste Exponencial (ax)');
    plot(distancias, promedios_maximos_ay, 'go-', 'DisplayName', 'ay');
    plot(distancias, ajuste_ay, 'g--', 'DisplayName', 'Ajuste Exponencial (ay)');
    plot(distancias, promedios_maximos_az, 'ro-', 'DisplayName', 'az');
    plot(distancias, ajuste_az, 'r--', 'DisplayName', 'Ajuste Exponencial (az)');
    title('Amplitudes promedio de las envolventes y ajuste exponencial respecto a la distancia');
    xlabel('Distancia (m)');
    ylabel('Amplitud (m/s²)');
    grid on;
    legend;
    hold off;

    % Mostrar las constantes de atenuación
    disp('Constantes de atenuación (B):');
    disp(['ax: ', num2str(params_ax(2))]);
    disp(['ay: ', num2str(params_ay(2))]);
    disp(['az: ', num2str(params_az(2))]);

catch ME
    disp('Error al ajustar la curva:');
    disp(ME.message);
end