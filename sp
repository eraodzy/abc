import random
from tqdm import tqdm
import numpy as np
import os

from plyfile import PlyData;
import pandas as pd
pathin = r"F:/point"
# pathin = r"C:\Users\yyd\Desktop\test"
pathout_all = r"F:/pointout"
pathout_param_all = r"F:/pointout"
# pathout_param_all = r"C:\Users\yyd\Desktop\param"
path_txt = ".txt"

def processing(plotno,j,data_temp2,data_Z,param):
    # 高度
    data_z = data_temp2[:, 2]
    leng = data_z.shape[0]
    if(leng>data_Z.shape[0]):
        leng = data_Z.shape[0]
        sampled = random.sample(range(data_z.shape[0]), leng)
        data_zz = data_z[sampled]
        data_zz = sorted(data_zz)
        data_Z[:leng, j - 1] = data_zz
    else:
        data_Z[:leng, j - 1] = data_z

    Min = min(data_z)
    Max = max(data_z)
    # 高度差
    height_difference = Max - Min

    data_z = data_z - Min  # 最低高度为0
    data_z = sorted(data_z)  # 排序

    # np.savetxt("{}".format(os.path.join(pathout_z, str(j) + path_txt)), data_z, fmt='%f', delimiter=" ")
    data_mean = np.mean(data_z)
    data_var = np.var(data_z)
    data_std = np.std(data_z)
    param[j - 1, :] = [data_mean, data_var, data_std, Max - Min]

    # 分高度统计点数
    # 层高
    differnce = 0.02;

    # 层数
    if (height_difference / differnce % differnce == 0.0):
        level_num = int(height_difference / differnce)
    else:
        level_num = int(height_difference / differnce) + 1
    arr = np.zeros((level_num))
    arr1 = np.zeros((level_num))   #保存的分层数
    for i in range(level_num):
        arr[i] = (i + 1) * differnce;

    idx = 0
    for i in range(len(data_z)):
        if (data_z[i] > arr[idx]):
            idx = idx + 1
        arr1[idx] = arr1[idx] + 1
    # 保存分成数据
    with open(os.path.join(pathout_param, "level" + path_txt), "a") as f:
        for i in range(len(arr1)):
            f.write(str(arr1[i])+'\t')
        # s = str(arr1)
        # s= s[1:len(s)-1]
        # f.write(s +'\n')
        f.write('\n')

    f.close()
    #一个文件
    with open(os.path.join(pathout_param_all, "level" + path_txt), "a") as f:
        if(j==1):
            f.write('Plot    ' + str(plotno) + '\t')
            f.write('\n')
        for i in range(len(arr1)):
            f.write(str(arr1[i])+'\t')
        # s = str(arr1)
        # s= s[1:len(s)-1]
        # f.write(s +'\n')
        f.write('\n')

    f.close()

    # 计算entropy
    arr1 = arr1[np.nonzero(arr1)[0]]
    percent = arr1 / sum(arr1)
    # print(percent)
    ln = np.log(percent)
    Sum = np.sum(-ln * percent)
    #保存
    with open(os.path.join(pathout_param, "entropy" + path_txt), "a") as f:
        f.write(str(Sum)+'\t')
        f.write('\n')
    f.close()

    #保存为一个文件
    with open(os.path.join(pathout_param_all, "entropy" + path_txt), "a") as f:
        if(j==1):
            f.write('Plot    ' + str(plotno) + '\t')
            f.write('\n')
        f.write(str(Sum)+'\t')
        f.write('\n')
    f.close()

    # print(j)
    j = j + 1
    return j,data_temp2,data_Z,param

paramall = np.array(['Mean  ','Variance   ','Standard   ','height difference'])
with tqdm(os.listdir(pathin)) as pbar:
    for file in pbar:

# for file in os.listdir(pathin):
        filename = file.split(".")[0]
        plot_no = int(filename.split("_")[-1])
        pathout = os.path.join(pathout_all,filename)
        if not os.path.isdir(pathout):
            os.makedirs(pathout)

        #创建参数文件夹
        pathout_param = os.path.join(pathout_param_all, filename)
        if not os.path.isdir(pathout_param):
            os.makedirs(pathout_param)


        #使用ply
        ply = PlyData.read(os.path.join(pathin,file))
        dataply = ply.elements[0].data
        data_pd = pd.DataFrame(dataply)  # 转换成DataFrame, 因为DataFrame可以解析结构化的数据
        data_np = np.array(data_pd)
        data = data_np
        #使用txt
        # data = np.loadtxt(os.path.join(pathin,file), dtype=float, delimiter=" ")

        # print(data.shape)
        data_x = data[np.argsort(data[:, 0])]
        x = data_x[data.shape[0] - 1, 0] - data_x[0, 0]
        data_y = data[np.argsort(data[:, 1])]
        y = data_y[data.shape[0] - 1, 1] - data_y[0, 1]
        # print(x, y)
        if(plot_no%3==0):
            num1 = 10
            num2 = 5
            board1 = 0.65  # 上下
            board2 = 0.55  # 左右
        else:
            num1 = 16
            num2 = 5
            board1 = 0.65  # 上下
            board2 = 0.55  # 左右


        param = np.zeros((num1*num2,4))
        data_Z = np.zeros((30200,num2*num1))

        length = (y - board1 * (num1 - 1)) / num1
        width = (x - board2 * (num2 - 1)) / num2
        min_y = 0
        j = 1
        if j == 80 :
            print("  s ")
        for index in range(data.shape[0]):
            #     if data_y[index,1]-data_y[0,1]<=0.2:
            #         min_y = index
            #         continue
            if data_y[index, 1] - data_y[min_y, 1] >= length:

                data_temp = data_y[min_y:index, :]
                for i in range(index, data.shape[0]):
                    if data_y[i, 1] - data_y[index, 1] >= board1:
                        min_y = i
                        break
                data_t_x = data_temp[np.argsort(data_temp[:, 0])]
                min_x = 0
                for index_x in range(data_t_x.shape[0]):
                    #             if data_t_x[index_x,0]-data_t_x[0,0]<=0.2:
                    #                 min_x = index_x
                    #                 continue
                    if data_t_x[index_x, 0] - data_t_x[min_x, 0] >= width:
                        data_temp2 = data_t_x[min_x:index_x, :]
                        for i in range(index_x, data_t_x.shape[0]):
                            if data_t_x[i, 0] - data_t_x[index_x, 0] >= board2:
                                min_x = i
                                break
                        np.savetxt("{}".format(os.path.join(pathout, str(j) + path_txt)), data_temp2, fmt='%f', delimiter=" ")

                        j,data_temp2,data_Z,param = processing(plot_no,j,data_temp2,data_Z,param)
                        pbar.set_postfix(File = file,Plot=j - 1,refresh=True)
                        # pbar.set_postfix(Plot=j - 1, refresh=True)

                    #             if data_t_x[index_x,0] - data_t_x[min_x,0]>=0.5:
                    #                 min_x = index_x
                    if index_x == (data_t_x.shape[0]) - 1:
                        data_temp2 = data_t_x[min_x:, :]
                        np.savetxt("{}".format(os.path.join(pathout, str(j) + path_txt)), data_temp2, fmt='%f', delimiter=" ")
                        j, data_temp2, data_Z, param = processing(plot_no,j, data_temp2, data_Z, param)
                        pbar.set_postfix(File = file,Plot=j - 1,refresh=True)

            #     if data_y[index,1]-data_y[min_y,1]>=0.5:
            #         min_y = index

            if index == (data.shape[0]) - 1:
                data_temp = data_y[min_y:, :]
                for i in range(index, data.shape[0]):
                    if data_y[i, 1] - data_y[index, 1] >= board1:
                        min_y = i
                        break
                data_t_x = data_temp[np.argsort(data_temp[:, 0])]
                min_x = 0
                for index_x in range(data_t_x.shape[0]):
                    if data_t_x[index_x, 0] - data_t_x[min_x, 0] >= width:
                        data_temp2 = data_t_x[min_x:index_x, :]
                        for i in range(index_x, data_t_x.shape[0]):
                            if data_t_x[i, 0] - data_t_x[index_x, 0] >= board2:
                                min_x = i
                                break
                        np.savetxt("{}".format(os.path.join(pathout, str(j) + path_txt)), data_temp2, fmt='%f', delimiter=" ")
                        j, data_temp2, data_Z, param = processing(plot_no,j, data_temp2, data_Z, param)
                        pbar.set_postfix(File = file,Plot=j-1, refresh=True)

                    if index_x == (data_t_x.shape[0]) - 1:
                        data_temp2 = data_t_x[min_x:, :]
                        np.savetxt("{}".format(os.path.join(pathout, str(j) + path_txt)), data_temp2, fmt='%f', delimiter=" ")
                        j, data_temp2, data_Z, param = processing(plot_no,j, data_temp2, data_Z, param)
                        pbar.set_postfix(File = file,Plot=j-1, refresh=True)
        paramall = np.vstack((paramall, param))
        np.savetxt("{}".format(os.path.join(pathout_param, "param" + path_txt)), np.vstack((['Mean  ','Variance   ','Standard   ','height difference'],param)), fmt='%s', delimiter=" ")
        np.savetxt("{}".format(os.path.join(pathout_param, "data_Z" + path_txt)), data_Z, fmt='%f', delimiter=" ")
np.savetxt("{}".format(os.path.join(pathout_param_all, "paramall" + path_txt)), paramall, fmt='%s', delimiter=" ")



